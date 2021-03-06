use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC;
use POE::Component::IRC::Plugin::BotCommand;
use POE::Component::Server::IRC;
use Test::More tests => 18;

my $bot1 = POE::Component::IRC->spawn(
    Flood        => 1,
    plugin_debug => 1,
);
my $bot2 = POE::Component::IRC->spawn(
    Flood        => 1,
    plugin_debug => 1,
);
my $ircd = POE::Component::Server::IRC->spawn(
    Auth      => 0,
    AntiFlood => 0,
);

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            _shutdown
            irc_001
            irc_join
            irc_disconnected
        )],
        main => {
            'irc_botcmd_cmd-1' => 'irc_botcmd_cmd1',
            'irc_botcmd_cmd-2' => 'irc_botcmd_cmd2',
        },
    ],
);

$poe_kernel->run();

sub _start {
    my ($kernel) = $_[KERNEL];

    $ircd->yield('register', 'all');
    $ircd->yield('add_listener');
    $kernel->delay(_shutdown => 60, 'Timed out');
}

sub ircd_listener_failure {
    my ($kernel, $op, $reason) = @_[KERNEL, ARG1, ARG3];
    $kernel->yield('_shutdown', "$op: $reason");
}

sub ircd_listener_add {
    my ($kernel, $port) = @_[KERNEL, ARG0];

    $bot1->yield(register => 'all');
    $bot1->yield(connect => {
        nick    => 'TestBot1',
        server  => '127.0.0.1',
        port    => $port,
    });

    $bot2->yield(register => 'all');
    $bot2->yield(connect => {
        nick    => 'TestBot2',
        server  => '127.0.0.1',
        port    => $port,
    });
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $ircd->yield('shutdown');
    $bot1->yield('shutdown');
    $bot2->yield('shutdown');
}

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();

    pass('Logged in');
    $irc->yield(join => '#testchannel');
    return if $irc != $bot1;

    my $plugin = POE::Component::IRC::Plugin::BotCommand->new(
        Addressed => 0,
        Prefix => '(', # regex metacharacter should not cause issues
        Commands => {
            'cmd-1' => 'First test command',
            foo     => 'This will get removed',
        },
    );

    ok($irc->plugin_add(BotCommand => $plugin), 'Add plugin with two commands');
    ok($plugin->add('cmd-2', 'Second test command'), 'Add another command');
    ok($plugin->remove('foo'), 'Remove command');

    my %cmds = $plugin->list();
    is(keys %cmds, 2, 'Correct number of commands');
    ok($cmds{'cmd-1'}, 'First command is present');
    ok($cmds{'cmd-2'}, 'Second command is present');
}

sub irc_join {
    my ($heap, $sender, $who, $where) = @_[HEAP, SENDER, ARG0, ARG1];
    my $nick = (split /!/, $who)[0];
    my $irc = $sender->get_heap();

    return if $nick ne $irc->nick_name();
    pass('Joined channel');
    $heap->{joined}++;
    return if $heap->{joined} != 2;

    # try command
    $bot2->yield(privmsg => $where, "(cmd-1 foo bar");

    # and one with color
    $bot2->yield(privmsg => $where, "\x02(cmd-2\x0f");
}

sub irc_botcmd_cmd1 {
    my ($sender, $user, $where, $args) = @_[SENDER, ARG0..ARG2];
    my $nick = (split /!/, $user)[0];
    my $irc = $sender->get_heap();

    is($nick, $bot2->nick_name(), 'Normal command (user)');
    is($where, '#testchannel', 'Normal command (channel)');
    is($args, 'foo bar', 'Normal command (arguments)');
}

sub irc_botcmd_cmd2 {
    my ($sender, $user, $where, $args) = @_[SENDER, ARG0..ARG2];
    my $nick = (split /!/, $user)[0];
    my $irc = $sender->get_heap();

    is($nick, $bot2->nick_name(), 'Colored command (user)');
    is($where, '#testchannel', 'Colored command (channel)');
    ok(!defined $args, 'Colored command (arguments)');

    $bot1->yield('quit');
    $bot2->yield('quit');
}

sub irc_disconnected {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    pass('irc_disconnected');
    $heap->{count}++;
    $poe_kernel->yield('_shutdown') if $heap->{count} == 2;
}
