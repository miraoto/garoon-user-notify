require 'open-uri'
require 'nokogiri'
require 'capybara/poltergeist'
require 'addressable/uri'
require 'net/http'
require 'json'

begin
  uid = ARGV[0]
  raise '引数にユーザーIDを入れてね ex) $ ruby ./notify.rb 123 ' if uid.nil? || uid !~ /\d+/
  Capybara.configure do |config|
    config.app_host = ENV['GAROON_URL']
  end
  Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app, {:js_errors => false, :timeout => 5000 })
  end

  session = Capybara::Session.new(:poltergeist)
  session.driver.headers = {
      'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2564.97 Safari/537.36"
  }
  session.visit(ENV['GAROON_ROOT_PATH'])
  session.within('form') do
    session.fill_in '_account', with: ENV['GAROON_ID']
    session.fill_in '_password', with: ENV['GAROON_PW']
    session.click_on 'ログイン'
  end
  session.visit("#{ENV['GAROON_ROOT_PATH']}schedule/personal_day?uid=#{uid}")
  html = session.html
  doc = Nokogiri::HTML.parse(html)
  user_name = doc.css('select')[0].children.map { |user| user.children[0].text if user.attribute('selected') }.compact[0]
  schedules = []
  doc.css('.event_content').each do |schedule|
    schedules.push(schedule.css('a').text)
  end
  notify = "今日の#{user_name}さん予定は" + "\n" + schedules.join("\n") + "\n になります"
  p notify
rescue StandardError => e
  raise e
end
