#!/bin/bash -e

DIRNAME=$( (cd $(dirname $0)/ && pwd) )
SRCDIR="${DIRNAME}/src"

source_checksum() {
  cd "${SRCDIR}"
  local check_sources="$(find . -name '*.rb' | grep -v vendor) Gemfile Gemfile.lock"
  cat ${check_sources} | md5
}

is_updated() {
  local checksum=$(source_checksum)
  if [[ ! -e "${DIRNAME}/.checksum" ]]; then
    echo "Updated, because checksum file is not found" >&2
    echo ${checksum} > "${DIRNAME}/.checksum"
    return 0
  fi
  if [[ ${checksum} == $(cat ${DIRNAME}/.checksum) ]]; then
    echo "Not updated, because checksum is not changed" >&2
    return 1
  fi
  echo "Updated, because checksum is changed" >&2
  return 0
}

re_install() {
  cd "${SRCDIR}"; rm -rf vendor
  bundle install --deployment --path vendor/bundle --without test 1>&2
}

archive_sources() {
  rm -f "${DIRNAME}/authorizer.zip"; cd "${SRCDIR}"
  local sources="$(find . -name '*.rb' | grep -v vendor) vendor"
  zip -qr "${DIRNAME}/authorizer.zip" ${sources} 1>&2
}

if is_updated ; then
  re_install && archive_sources
fi

cd "${DIRNAME}"
echo "{ \"filename\": \"${DIRNAME}/authorizer.zip\" }"
