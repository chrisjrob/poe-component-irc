use Test::More tests => 28;
use_ok("POE::Filter::IRC::Compat");
use_ok("POE::Filter::IRC");
use_ok("POE::Filter::CTCP");
use_ok("POE::Component::IRC");
use_ok("POE::Component::IRC::State");
use_ok("POE::Component::IRC::Qnet");
use_ok("POE::Component::IRC::Qnet::State");
use_ok("POE::Component::IRC::Pipeline");
use_ok("POE::Component::IRC::Constants");
use_ok("POE::Component::IRC::Common");
use_ok("POE::Component::IRC::Test::Plugin");
use_ok("POE::Component::IRC::Test::Harness");
use_ok("POE::Component::IRC::Projects");
use_ok("POE::Component::IRC::Plugin");
use_ok("POE::Component::IRC::Plugin::Whois");
use_ok("POE::Component::IRC::Plugin::Proxy");
use_ok("POE::Component::IRC::Plugin::PlugMan");
use_ok("POE::Component::IRC::Plugin::NickServID");
use_ok("POE::Component::IRC::Plugin::NickReclaim");
use_ok("POE::Component::IRC::Plugin::Logger");
use_ok("POE::Component::IRC::Plugin::ISupport");
use_ok("POE::Component::IRC::Plugin::FollowTail");
use_ok("POE::Component::IRC::Plugin::Console");
use_ok("POE::Component::IRC::Plugin::Connector");
use_ok("POE::Component::IRC::Plugin::CTCP");
use_ok("POE::Component::IRC::Plugin::BotTraffic");
use_ok("POE::Component::IRC::Plugin::BotAddressed");
use_ok("POE::Component::IRC::Plugin::AutoJoin");
