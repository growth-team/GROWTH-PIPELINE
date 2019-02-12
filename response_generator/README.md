# GROWTH RESPONSE GENERATOR
Ver. 1.0 (2018 May 24th)

## 概要
GROWTH RESPONSE GENERATORは、GEANT4シミュレーションによって作成したガンマ線とシンチレータの相互作用のイベントリストから、XSPECでのスペクトル解析に必要なレスポンスファイルを作成するソフトウェアです。[XSPECの詳細についてはこちら](https://heasarc.gsfc.nasa.gov/xanadu/xspec/)を、[レスポンスファイルの詳細についてはこちら](https://heasarc.gsfc.nasa.gov/docs/xanadu/xspec/fits/fitsfiles.html)を参照してください。

## 動作環境
本ソフトウェアはRubyで動作します。動作にはRuby 2.3.x以上、[RubyROOT](https://github.com/odakahirokazu/RubyROOT)、[RubyFits](https://github.com/yuasatakayuki/RubyFits)、およびこれらを動かすために必要なソフトウェア ([ROOT](https://root.cern.ch/)、[SFITSIO](https://www.ir.isas.jaxa.jp/~cyamauch/sli/index.ni.html)など) が必要となります。

## 各ファイルの説明と使用方法
### response_generator.rb
メインのレスポンス作成スクリプトです。使い方は以下のとおりです。

`ruby response_generator.rb [ROOTファイルリスト] [レスポンスファイル] [検出器名] [イベントリスト名] [数密度] [ビン定義ファイル] [分解能パラメータ1] [分解能パラメータ2] [分解能パラメータ3]`

ROOTファイルリストは、GEANT4で作成したイベントリストが入っているROOTファイルのリストをテキストで書き出したものです。response_generator.rbを実行しているディレクトリからの相対パス、または絶対パスで記述してください。(自前のワークステーションでシミュレーションを行い、出力のROOTファイルが1つの場合はこの方式は面倒ですが、サーバやスパコンなどで並列処理を行い、複数のROOTファイルを読み込むのに対応したものです。)

レスポンスファイルは出力されるファイル名です。.rspの拡張子をつけると良いでしょう。

イベントリスト名ではROOTファイルにTTree形式で格納されているイベントリストの名前を指定してください。`root [ROOTファイル名]`でROOTファイルを開き、`.ls`コマンドでイベントリスト名を確認できます。GROWTHチームでは通常eventListという名前を使用しています。

数密度はシミュレーションで発生させた粒子の面積あたりの個数です。単位は個/cm^2です。例えばGEANT4シミュレーションでガンマ線を100 cm × 100 cmの領域で1e5コ発生させた場合、数密度は1e8 コ/1e4 cm^2 = 1e4 コ/cm^2 となります。GROWTHチームでは1e5個以上の統計を推奨しています。

ビン定義ファイルはレスポンスを作成する際のエネルギービンを定義するファイルです。レスポンスファイルではシミュレーションで発生させたガンマ線の初期エネルギー別に検出器でのスペクトルを格納しています。ビン定義ファイルはその初期エネルギーの区切りを定義しています。GROWTHチームでは標準で`work_file/inputEnergyBin.txt`を使用しています。

分解能パラメータ (1−3) は実際の検出器応答に合わせてエネルギー別のエネルギー分解能を算出するのに用います。エネルギー分解能は

分解能 (MeV) = [パラメータ1] × [エネルギー (MeV)] ^[パラメータ2] + [パラメータ3]

で計算されます。ここで分解能はガウシアンのsigmaに相当します。パラメータの値は実際の検出器での測定結果から40K、208Tl、214Biに由来する輝線幅を算出して、計算してください。MeV単位で計算されることに留意してください。

### makeResponse.rb
response_generator.rbを動かすシェルスクリプトです。直接response_generator.rbを実行しても問題ありません。パラメータの参考値・response_generator.rbの使用方法の参考としてご利用ください。

### growth-fy2016a.rsp
レスポンスのサンプルファイルです。ファイル構造などは[fv](https://heasarc.gsfc.nasa.gov/ftools/fv/)で確認することができます。ただし光子統計が少ないため、実際の使用には向きません。

### work_file/inputEnergyBin.txt
ビン定義ファイルです。

### work_file/root_list.dat
ROOTファイルのリストファイル (参考) です。
