require 'sinatra'
require 'net/http'
require 'uri'
require 'json'
require 'bundler'
require 'cgi'

Bundler.require

memo_hash = {}

get '/memos/top' do
  memo_hash = json_file_open

  # ハッシュに格納されたメモデータのリンクを表示
  @t = ''
  if memo_hash['memos'].empty?
    @t = '<p>メモがありません</p>'
  else
    memo_hash['memos'].each do |memo|
      @t += "<a href=\"/memos/#{memo['id']}/show\"><p>#{memo['title']}</p><br>"
    end
  end

  @t += '<a href="/new">追加</a>'
  erb :top
end

get '/memos/:id/show' do
  # URLからクリックしたメモのタイトルに対応するIDを取得し
  # 表示するメモを指定するインデックスとして設定
  id = params[:id]
  memo_index = id.to_i - 1

  memo_hash = json_file_open

  @t = ''
  @t += "<h2>#{memo_hash['memos'][memo_index]['title']}</h2>"
  @t += "<p>#{memo_hash['memos'][memo_index]['contents']}</p>"
  @t += "<a href=\"/memos/#{id}/edit\">編集</a><br>"
  @t += "<form action=\"/memos/#{id}/del\" method=\"post\">"
  @t += '<input type="submit" value="削除">'
  @t += "<input type=\"hidden\" name=\"id\" value=\"#{id}\">"
  @t += '<input type="hidden" name="_method" value="delete">'
  @t += '</form>'

  erb :show
end

get '/new' do
  erb :new
end

post '/new_' do
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

  redirect '/memos/top'
end

get '/memos/:id/edit' do
  id = params[:id]

  memo_hash = json_file_open

  @t = ''
  memo_hash['memos'].each do |memo|
    next unless memo['id'] == id

    # URLに含まれているメモIDと一致するIDをハッシュから探し出し、編集画面のタイトルと内容のテキストに表示する
    @t += "<form action=\"/edit_/#{id}\" method=\"post\">"
    @t += '<input id="hidden" type="hidden" name="_method" value="patch">'
    @t += '<h2>タイトル</h2><br>'
    @t += "<input type=\"text\" size=\"30\" maxlength=\"20\" value=\"#{memo['title']}\" name=\"title\"><br>"
    @t += '<h3>内容</h3><br>'
    @t += "<textarea cols=\"40\" rows=\"20\" maxlength=\"100\" name=\"contents\">#{memo['contents']}</textarea><br>"
    @t += '<input type="submit" value="保存">'
    @t += '</form>'
    @t += "<a href=\"/memos/#{id}/show\">キャンセル</a>"
    break
  end

  erb :edit
end

patch '/edit_/:id' do
  # URLから編集するメモのデータを取り出す
  id = params[:id]

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
  path << '/show'

  redirect path
end

delete '/memos/:id/del' do
  # URLから削除するメモのIDを取り出し
  # 削除するメモのインデックスを指定
  id = params[:id].to_i
  memo_index = id - 1

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

  File.open('memos.json', 'w') do |file|
    JSON.dump(memo_hash, file)
  end

  redirect '/memos/top'
end

# メモデータが格納されているJSONファイルを開き、ハッシュに格納するメソッド
def json_file_open
  f = File.open('memos.json')
  json_memo = f.read
  f.close
  JSON.parse(json_memo)
end

# メモデータのハッシュを受け取り、JSONファイルに上書きするメソッド
def json_file_write(arg_hash)
  File.open('memos.json', 'w') do |file|
    JSON.dump(arg_hash, file)
  end
end
