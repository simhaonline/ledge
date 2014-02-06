use Test::Nginx::Socket;
use Cwd qw(cwd);

plan tests => repeat_each() * (blocks() * 2); 

my $pwd = cwd();

$ENV{TEST_LEDGE_REDIS_DATABASE} ||= 1;

our $HttpConfig = qq{
    lua_package_path "$pwd/../lua-resty-qless/lib/?.lua;$pwd/../lua-resty-http/lib/?.lua;$pwd/lib/?.lua;;";
    init_by_lua "
        ledge_mod = require 'ledge.ledge'
        ledge = ledge_mod:new()
        ledge:config_set('redis_database', $ENV{TEST_LEDGE_REDIS_DATABASE})
        ledge:config_set('upstream_host', '127.0.0.1')
        ledge:config_set('upstream_port', 1984)
        redis_socket = '$ENV{TEST_LEDGE_REDIS_SOCKET}'
    ";
};

no_long_string();
run_tests();

__DATA__
=== TEST 1: Update response provided to closure
--- http_config eval: $::HttpConfig
--- config
location /events_1_prx {
    rewrite ^(.*)_prx$ $1 break;
    content_by_lua '
        ledge:bind("response_ready", function(res)
            res.header["X-Modified"] = "Modified"
        end)
        ledge:run()
    ';
}
location /events_1 {
    echo "ORIGIN";
}
--- request
GET /events_1_prx
--- response_headers
X-Modified: Modified

