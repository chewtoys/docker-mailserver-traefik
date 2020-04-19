load 'libs/bats-support/load'
load 'libs/bats-assert/load'
load 'test_helper/common'

function setup() {
  DOCKER_FILE_TESTS="$BATS_TEST_DIRNAME/files/docker-compose.traefik.v1.consul.new-container.yml"
  export PUSH_PERIOD="0" # push disabled

  run_setup_file_if_necessary
}

function teardown() {
  unset PUSH_PERIOD
  run_teardown_file_if_necessary
}

@test "first" {
    skip "only used to call setup_file from setup: $( basename $BATS_TEST_FILENAME )"
}

@test "check: no push existing certificate to newly created container" {

    # wait push has been done
    run repeat_until_success_or_timeout "$TEST_TIMEOUT_IN_SECONDS" sh -c "docker logs ${TEST_STACK_NAME}_mailserver-traefik_1 | grep -F \"Pushing mail.localhost.com\""
    assert_success
    first_push_time=$( date +%s )

    # up mailserver
    run docker-compose -p "$TEST_STACK_NAME" -f "$DOCKER_FILE_TESTS" up -d mailserver
    assert_success

    # wait some time...
    sleep 10

    # test presence of certificates
    run docker exec "${TEST_STACK_NAME}_mailserver_1" ls /etc/postfix/ssl/cert
    assert_output --partial 'No such file or directory'
    run docker exec "${TEST_STACK_NAME}_mailserver_1" ls /etc/postfix/ssl/key
    assert_output --partial 'No such file or directory'
}

@test "last" {
    skip 'only used to call teardown_file from teardown'
}

setup_file() {
  initAcmejson
  docker-compose -p "$TEST_STACK_NAME" -f "$DOCKER_FILE_TESTS" down -v --remove-orphans
  docker-compose -p "$TEST_STACK_NAME" -f "$DOCKER_FILE_TESTS" up -d traefik consul-leader pebble challtestsrv

  # wait traefik+pebble are up
  run repeat_until_success_or_timeout "$TEST_TIMEOUT_IN_SECONDS" sh -c "docker logs ${TEST_STACK_NAME}_traefik_1 | grep -F \"Got certificate for domains [mail.localhost.com]\""
  assert_success
  # then up the renewer
  run docker-compose -p "$TEST_STACK_NAME" -f "$DOCKER_FILE_TESTS" up -d mailserver-traefik
  assert_success
}

teardown_file() {
  docker-compose -p "$TEST_STACK_NAME" -f "$DOCKER_FILE_TESTS" down -v --remove-orphans
}