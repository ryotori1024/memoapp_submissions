require 'sinatra'
require 'net/http'
require 'uri'
require 'json'
require 'bundler'
require 'cgi'

Bundler.require

get '/memos' do
  memo_hash = {}
  memo_hash = json_file_open

  # トップ画面に表示するデータをセット
  @id = []
  @title = []
  @memos_length = memo_hash['memos'].length

  memo_hash['memos'].each do |memo|
    @id.push(memo['id'])
    @title.push(memo['title'])
  end

  erb :top
end

get '/memos/:id/detail' do
  # URLからクリックしたメモのタイトルに対応するIDを取得し
  # 表示するメモを指定するインデックスとして設定
  memo_index = params[:id].to_i - 1

  memo_hash = {}
  memo_hash = json_file_open

  # 内容閲覧画面で表示するデータをセット
  @id = params[:id]
  @title = memo_hash['memos'][memo_index]['title']
  @contents = memo_hash['memos'][memo_index]['contents']

  erb :show
end

get '/memos/new' do
  erb :new
end

post '/new' do
  memo_hash = {}
  memo_hash = json_file_open

  max_id = 0
  memo_hash['memos'].each do |memo|
    # 格納されているメモの中で最大のIDを求め、その数値+1を新しく追加するメモのIDとする
    max_id = memo['id'].to_i if memo['id'].to_i > max_id
  end
  max_id += 1

  # 新規画面で入力したメモのタイトルと内容をサニタイジングする
  title_sanit = CGI.escapeHTML(params[:title])
  contents_sanit = CGI.escapeHTML(params[:contents])

  # 新規画面で入力したメモのタイトルと内容をハッシュに格納する
  memo_hash['memos'].push({ "id": max_id.to_s, "title": title_sanit, "contents": contents_sanit })

  json_file_write(memo_hash)

  redirect '/memos'
end

get '/memos/:id/edit' do
  memo_hash = {}
  memo_hash = json_file_open

  memo_hash['memos'].each do |memo|
    next unless memo['id'] == params[:id]

    # URLに含まれているメモIDに対応するメモのタイトルと内容をインスタンス変数にセット
    @id = params[:id]
    @title = memo['title']
    @contents = memo['contents']
    break
  end

  erb :edit
end

patch '/memos/:id' do
  # URLから編集するメモのデータを取り出す
  id = params[:id]

  memo_hash = {}
  memo_hash = json_file_open

  # 編集画面で入力したメモのタイトルと内容をサニタイジングする
  title_sanit = CGI.escapeHTML(params[:title])
  contents_sanit = CGI.escapeHTML(params[:contents])

  memo_hash['memos'].each do |memo|
    next unless memo['id'] == id

    # URLから取得したIDとハッシュのIDが等しければ、編集したタイトルと内容をハッシュに格納
    memo['title'] = title_sanit
    memo['contents'] = contents_sanit
  end

  json_file_write(memo_hash)

  path = '/memos/'
  path << id
  path << '/detail'

  redirect path
end

delete '/memos/:id' do
  # URLから削除するメモのIDを取り出し
  # 削除するメモのインデックスを指定
  id = params[:id].to_i
  memo_index = id - 1

  memo_hash = {}
  memo_hash = json_file_open

  # 削除したメモデータから数えていくつ分のメモデータのIDを更新するかを求める
  times = memo_hash['memos'].length - memo_index - 1
  # 該当するインデックスのメモデータを削除
  memo_hash['memos'].delete_at(memo_index)

  # メモデータを削除した場合に、IDが中抜けになり整合が取れなくなるのを防ぐために
  # 削除したメモ以降のデータのIDを-1する
  if times != 0
    # timesが0(一番後ろのメモデータを削除)の場合は行わない
    times.times do
      memo_hash['memos'][memo_index]['id'] = (memo_hash['memos'][memo_index]['id'].to_i - 1).to_s
      memo_index += 1
    end
  end

  json_file_write(memo_hash)

  redirect '/memos'
end

# メモデータが格納されているJSONファイルを開き、ハッシュに格納するメソッド
def json_file_open
  json_memo = File.read('memos.json')
  JSON.parse(json_memo)
end

# メモデータのハッシュを受け取り、JSONファイルに上書きするメソッド
def json_file_write(arg_hash)
  File.open('memos.json', 'w') do |file|
    JSON.dump(arg_hash, file)
  end
end
