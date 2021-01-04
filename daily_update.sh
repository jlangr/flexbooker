#!/bin/bash

PATH=$PATH:/Users/jlangr/.rvm/gems/ruby-2.5.5/bin:/Users/jlangr/.rvm/gems/ruby-2.5.5@global/bin:/Users/jlangr/.rvm/rubies/ruby-2.5.5/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:/Users/jlangr/.rvm/bin

#rvm cron setup

rm -rf pubmob
git clone git@github.com:pubmob-com/pubmob.git
pwd

echo Updating...
if ~/flexbooker/update_next_available_dates ~/flexbooker/pubmob ; then
  echo update successful
else
  echo update failed
fi

cd pubmob
git add -A
git diff-index --quiet HEAD || git commit -m "updated times batch update"
git push
echo Pushed updated times
# rm -rf pubmob
