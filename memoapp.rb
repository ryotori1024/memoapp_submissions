require 'sinatra'
require 'net/http'
require 'uri'
require 'json'
require 'bundler'

Bundler.require

get '/memos' do
  memo_hash = json_file_open

  # トップ画面に表示するデータをセット
  @memos = memo_hash['memos']

  erb :top
end

get %r{/memos/([0-9]+)} do |id|
  memo_hash = json_file_open

  # URLに含まれているメモIDに対応するメモをインスタンス変数にセット
  @memo = memo_hash['memos'].find { |memo| memo['id'] == id }

  erb :show
end

get '/memos/new' do
  erb :new
end

post '/memos' do
  memo_hash = json_file_open

  # 格納されているメモの中で最大のIDを求め、その数値+1を新しく追加するメモのIDとする
  max_id = memo_hash['memos'].map { |memo| memo['id'] }.max.to_i + 1

  # 新規画面で入力したメモのタイトルと内容をハッシュに格納する
  memo_hash['memos'].push({ "id": max_id.to_s, "title": params[:title],
                            "contents": params[:contents] })

  json_file_write(memo_hash)

  redirect '/memos'
end

get '/memos/:id/edit' do
  memo_hash = json_file_open

  # URLに含まれているメモIDに対応するメモをインスタンス変数にセット
  @memo = memo_hash['memos'].find { |memo| memo['id'] == params[:id] }

  erb :edit
end

patch '/memos/:id' do
  memo_hash = json_file_open

  # URLに含まれているメモIDに対応するメモを編集する
  memo = memo_hash['memos'].find { |m| m['id'] == params[:id] }
  memo['title'] = params[:title]
  memo['contents'] = params[:contents]

  json_file_write(memo_hash)

  redirect "/memos/#{params[:id]}"
end

delete '/memos/:id' do
  memo_hash = json_file_open

  # URLに含まれるメモIDと同じIDのメモを削除する
  memo_hash['memos'].delete_if { |memo| memo['id'] == params[:id] }

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
