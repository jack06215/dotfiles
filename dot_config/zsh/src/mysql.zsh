# ==== MySQL client flags (asdf or Homebrew) ==================================
if command -v asdf >/dev/null 2>&1; then
  mysql_prefix="$(asdf where mysql 2>/dev/null | tr -d '\n')"
  if [[ -n "$mysql_prefix" && -d "$mysql_prefix" ]]; then
    export MYSQLCLIENT_CFLAGS="-I${mysql_prefix}/include"
    if [[ -f "${mysql_prefix}/lib/libmysqlclient.a" ]]; then
      export MYSQLCLIENT_LDFLAGS="-L${mysql_prefix}/lib -lmysqlclient -lpthread -lm -ldl"
    fi
  fi
fi
