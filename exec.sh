#!/bin/bash
echo 'exec!!'
#/usr/bin/ruby /usr/local/selenium_test/script.rb
/bin/bash -cl 'cd /usr/local/selenium_test && source server_env.sh && ruby script.rb'
