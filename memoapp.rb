require 'sinatra'
require 'net/http'
require 'uri'
require 'json'
require 'bundler'
require 'cgi'

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
  @memos = memo_hash['memos'].find { |memo| memo['id'] == id }

  erb :show
end

get '/memos/new' do
  erb :new
end

post '/new' do
  memo_hash = json_file_open

  # 格納されているメモの中で最大のIDを求め、その数値+1を新しく追加するメモのIDとする
  max_id = memo_hash['memos'].map { |memo| memo['id'] }.max.to_i + 1

  # 新規画面で入力したメモのタイトルと内容をハッシュに格納する
  memo_hash['memos'].push({ "id": max_id.to_s, "title": CGI.escapeHTML(params[:title]),
                            "contents": CGI.escapeHTML(params[:contents]) })

  json_file_write(memo_hash)

  redirect '/memos'
end

get '/memos/:id/edit' do
  memo_hash = json_file_open

  # URLに含まれているメモIDに対応するメモをインスタンス変数にセット
  @memos = memo_hash['memos'].find { |memo| memo['id'] == params[:id] }

  erb :edit
end

patch '/memos/:id' do
  memo_hash = json_file_open

  memo_hash['memos'].each do |memo|
    next unless memo['id'] == params[:id]

    # URLから取得したIDとハッシュのIDが等しければ、編集したタイトルと内容をハッシュに格納
    memo['title'] = CGI.escapeHTML(params[:title])
    memo['contents'] = CGI.escapeHTML(params[:contents])
  end

  json_file_write(memo_hash)

  redirect "/memos/#{params[:id]}"
end

delete '/memos/:id' do
  memo_hash = json_file_open

  memo_hash['memos'].each_with_index do |memo, index|
    if memo['id'] == params[:id]
      # URLに含まれるメモIDと同じIDのメモを探し、そのインデックスのメモを削除する
      memo_hash['memos'].delete_at(index)
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
