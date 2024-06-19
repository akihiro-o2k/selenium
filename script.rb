# frozen_string_literal: true
#
# Refs:
# Selenium::WebDriver
# -> https://www.rubydoc.info/gems/selenium-webdriver/Selenium/WebDriver
#
# Class Selenium::WebDriver::Chrome::Options:
# -> https://www.selenium.dev/selenium/docs/api/rb/Selenium/WebDriver/Chrome/Options.html
require 'selenium-webdriver'
require "#{Dir.pwd}/http_connection"
require 'date'
require 'yaml'
require 'erb'
require 'logger'
require 'browsermob/proxy'
LOG_FILE = './log/script.log'

# logファイル記載処理のメソッド切り出し
def logger(param, type = nil)
  File.write(LOG_FILE,'') unless File.exist?(LOG_FILE)
  log = Logger.new(LOG_FILE)
  type.nil? ? log.info(param) : log.error(param)
end

# Chrom optionをメソッド切り出し。
def selenium_options
  # optionの指定
  options = Selenium::WebDriver::Chrome::Options.new
  # メモリ省力化設定 --headlessでコマンドラインからchromeを開く。GUIよりこっちの方が軽い。
  options.add_argument('--headless')
  # 「暫定的なフラグ」らしい。。
  options.add_argument('--disable-gpu')
  # セキュリティ対策などのchromeに搭載してある保護機能をオフにする。
  options.add_argument('--no-sandbox')
  # ディスクのメモリスペースを使う。
  options.add_argument('--disable-dev-shm-usage')
  # リモートデバッグフラグを立てる。
  options.add_argument('--remote-debugging-port=9222')
  # window-size指定
  options.add_argument("--window-size=1920,1080")
  # proxy
  options.add_argument("--proxy-server=http://erproxy.noc.ntt.com:50080")
  # 戻り値
  options
end

# 実行環境の判定
ENVIROMENT = ENV['ENVIROMENT'] ? ENV['ENVIROMENT'] : 'development'
# パラメータの読み込み
SETTING = YAML.load(ERB.new(File.read('setting.yaml')).result).freeze
# logger用の定義済み文字列を使いやすく変数代入
msg = SETTING['messages']
# backlogの当日ディレクトリ定義
logdir = "#{SETTING['common']['backlog_dir']}#{Time.now.strftime('%Y%m%d')}"
# 当日ディレクトリ判定。なければ作成
Dir.mkdir(logdir, 0775) unless Dir.exist?(logdir)
# back_logファイルをフルパスで定義
BACK_LOG = "#{logdir}/#{Time.now.strftime('%Y%m%d_%H%M')}.png"
# 環境に特化した設定値の取得
s = SETTING[ENVIROMENT]
#
# 以下、Selenium::WebDriver使用でスクリーンショットを取得する処理本体
begin
  # seleinum_optionsメソットでオプション指定してchromeをdirverに定義
  driver = Selenium::WebDriver.for :chrome, options: selenium_options
  # 10秒待っても読み込まれない場合は、エラーが発生する
  driver.manage.timeouts.implicit_wait = 10

  # guard節 http_connectionで対象が設定済みTimeOut値以内にstatus=200を返す事を事前確認(ERROR時はLogに記載して終了)
  HttpConnection.response_code == '302' ? logger("#{msg[0]}success") :  raise("#{msg[0]} #{HttpConnection.response_code}")

  # Selenium処理；ページ遷移する
  driver.navigate.to(s['url'])
  sleep(10)
  # htmlのtitle文字列参照で想定する画面か判定する。
  #driver.title.strip =~ s['title'] ? logger("#{msg[1]}success") : raise("#{msg[1]}failed(script exit)") 
  # 検索フォームの取得(id属性で取得->値の代入)
  driver.find_element(id: s['user_name_object']).send_keys(s['user_name_param'])
  driver.find_element(id: s['password_object']).send_keys(s['password_param'])
  # 送信(検索)
  driver.find_element(:xpath, s['submit_object']).click
  # 遅延処理 待機処理が無いとページ遷移前にスクリーンショットされてしまうため)
  sleep(s['login_wait_time'].to_i)
#=begin
  # 商用環境->ボタンを押下する処理を実施
  if ENVIROMENT == 'production'
    #driver.find_element(:xpath, s['button_element']).click
    #sleep(3)
    driver.save_screenshot(BACK_LOG)
    # ファイルの存在有無で成功判定。ここでは後続のlogout処理の関係でraise せずにloggerで失敗を記録。
    result = File.exist?(BACK_LOG) ? logger("#{msg[2]}successfully!(#{File.basename(BACK_LOG)})") : logger("#{msg[2]}feiled...", 'e')
    sleep(2)
  end
#=end
  # latest.pngのスクリーンショットを作成
  driver.save_screenshot(SETTING['common']['default_file'])
  logger("[4]Update #{SETTING['common']['default_file']} successfully!!") if File.exist?(SETTING['common']['default_file'])
  sleep(2)
#=begin
  # 商用環境ではログアウト処理を実施
  if ENVIROMENT == 'production'
    #logout
    driver.find_element(:xpath, s['dropdown_object']).click
    sleep(3)
    driver.find_element(:xpath, s['logout_object']).click
    sleep(3)
  end
#=end
rescue => e
  # エラー内容をログ出力
  logger(e.message, 'e')
  # error.htmlをスクリーンショットするための画面遷移
  driver.navigate.to(SETTING[ENVIROMENT]['error_url'])
  sleep(1)
  # 規定のパスにerror.htmlをスクリーンショットする。
  driver.save_screenshot(SETTING['common']['default_file'])
ensure
  # ブラウザを終了
  driver.quit unless driver.nil?
end
