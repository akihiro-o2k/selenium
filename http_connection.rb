# frozen_string_literal: true
require 'net/http'
require 'yaml'

# httpConection class
#
# setting.yamlで指定のURLにアクセスして、httpのresponse status codeを戻す。
# error時はNet::HTTP.startのerror.messageを戻す。
class HttpConnection
  # 設定の読み込み
  SETTING = YAML.load_file('setting.yaml').freeze
  # 実行環境の判定
  ENVIROMENT = ENV['ENVIROMENT'] ? ENV['ENVIROMENT'] : 'development'

  # 対象URLのステータスを戻すクラスメソッド
  def self.response_code
  begin
    uri = URI.parse(SETTING[ENVIROMENT]['url'])
    # URLに接続してステータスコードを戻す
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') {|http|
      http.open_timeout = SETTING['common']['open_timeout']
      http.read_timeout = SETTING['common']['read_timeout']
      http.get(uri.request_uri)
    }
    response.code
  rescue => e
    # Error.messageを戻す。
    e.message 
  end
  end
end
