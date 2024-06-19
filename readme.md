# (仮称)コンテンツ提供,検証ソース置き場

## 目的
- 見える化案件でNPMのスクリーンショットを自動取得を行い、NPMのアカウントを持たない統合網の利用者へ現在のトラフィックを見えるようにする。

## 業務要件
- 当該施策を便宜的に「(仮称)コンテンツ提供」と呼称し、以下の業務要件を満たすスクリプトの作成をゴールとする。

1. 取得するスクリーンショット(以降「SS」と省略表記)は、第三者がWebよりhttpアクセス可能な状態とする。
1. 最新SSを同一ファイル名称で保存し、常に上書き処理を行う。
1. 上記同一ファイル名称のもの意外に取得年月日時分単位で特定ディレクトリに格納する。
    - 削除処理に関しては別途定義する。
1. スクリプトの実行結果を別途定めるファイルにログとして書き出しを行う。

### 検証内容
- chrome-driverを使用して目的を実券する。
  - script.rbが動くサンプルとなっております。
- 前提条件
  - 構築時にansible/serverspec実行環境として用意した「管理用VM」をスクリプト実行の動作ホストとする。
    - 具体的に必要となる環境はruby動作環境。
    - その他、ネイティブアプリケーションとしてgooble-chrome, chrome-driver, rubyのライブラリとして`selenium-webdriver`の追加インストールが必要となる。

## 環境設定メモ
- 以下、検証要VMで環境構築を行った内容のメモ。

### install google-chrome

```bash
# add apt repository
sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >>/etc/apt/sources.list.d/google.list'
# add repos-key
sudo wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
# update packege-list & install google-chrome
sudo apt update && sudo apt install google-chrome-stable

# check installed chreme-version
google-chrome --version
#->Google Chrome 114.0.5735.133
```

### install chrome-driver
- chrome-driverのインストール。下記のサイトでインストールしたgoogle-chromeとマイナーバージョンまで合致するドライバーの有無を確認。
  - 検証端末上ではマイナーバージョンまで合っていればパッチレベルはマッチしなくても動いた。
- [check stable-chrome-drivers](https://chromedriver.storage.googleapis.com/)
- [ChromeDriver - WebDriver for Chrome](https://sites.google.com/a/chromium.org/chromedriver/downloads)

```bash
# 環境変数に事前確認したgoogle-chrome --versionの結果に対して上記URLで一番近いバージョンを環境変数CHROME_VERSIONに代入。
export CHROME_VERSION=114.0.5735.90
# バージョン指定のchromedriverのzipファイルをダウンロード
sudo wget https://chromedriver.storage.googleapis.com/$CHROME_VERSION/chromedriver_linux64.zip
# zip解凍
sudo unzip chromedriver_linux64.zip
# 実行ファイルとして配備
sudo mv chromedriver /usr/local/bin/
# 配備したファイルにパスが通っていることの確認。
whereis chromedriver
# versionコマンドで実行可能であることの確認。
chromedriver --version
```

### add ruby gems 'selenum-webdriver'

```bash
sudo gem install selenium-webdriver -v 4.9.0
```

## 環境変数
- 以下のサーバー環境変数を必須パラメーターとする。
  - ENVIROMENT
  - SELENIUM_LOGIN_USER
  - SELENIUM_LOGIN_PASS

## 実行コマンド
- 当該リポジトリをワーキングディレクトリとして下記コマンドで実行可能
  ```bash
  ruby script.rb
  ```
- 実行結果の成功時はscreenshot.pngが生成される。

### 参考文章

- [RubyでWebスクレイピング](https://ytnk531.hatenablog.com/entry/2020/11/16/060407)
- [メモリ省力化設定](https://zaitaku-tushin.com/2023/06/07/%e3%83%a1%e3%83%a2%e3%83%aa%e7%9c%81%e5%8a%9b%e5%8c%96%e8%a8%ad%e5%ae%9a%e3%82%92%e5%85%a5%e3%82%8c%e3%81%a6%e3%80%8cseleniumwebdrivererrorunknownerror-unknown-error-session-deleted-because-of/)
