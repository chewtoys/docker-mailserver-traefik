load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'test_helper/common'

function setup() {
  DOCKER_FILE_TESTS="$BATS_TEST_DIRNAME/files/docker-compose.traefik.v1.boltdb.yml"
  run_setup_file_if_necessary
}

function teardown() {
  run_teardown_file_if_necessary
}

@test "first" {
    skip 'only used to call setup_file from setup'
}


@test "check: certificate mail.localhost.com received on mailserver container" {

    # test script has been triggered on mailserver
    run repeat_until_success_or_timeout 30 sh -c "docker logs ${TEST_STACK_NAME}_mailserver-traefik_1 | grep -F \"[INFO] mail.localhost.com - new certificate '/tmp/ssl/fullchain.pem' received on mailserver container\""
    assert_success

    # test trigger script completion
    run repeat_until_success_or_timeout 30 sh -c "docker logs ${TEST_STACK_NAME}_mailserver-traefik_1 | grep -F '[INFO] mail.localhost.com - Cert update: new certificate copied into container'"
    assert_success

    # test presence of certificates
    run docker exec "${TEST_STACK_NAME}_mailserver_1" ls /etc/postfix/ssl/
    assert_output --partial 'cert'
    assert_output --partial 'key'
}

@test "last" {
    skip 'only used to call teardown_file from teardown'
}

setup_file() {
  docker-compose -p "$TEST_STACK_NAME" -f "$DOCKER_FILE_TESTS" down -v --remove-orphans
  docker-compose -p "$TEST_STACK_NAME" -f "$DOCKER_FILE_TESTS" up -d
}

teardown_file() {
  docker-compose -p "$TEST_STACK_NAME" -f "$DOCKER_FILE_TESTS" down -v --remove-orphans
}