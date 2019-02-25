require 'spec_helper'
require 'logger'

LOGGER = Logger.new(STDOUT)

USER_1 = {
  name: 'test1',
  id: '1',
  group_id: '1',
  keys: ['test1']
}

USER_2 = {
  name: 'test2',
  id: '2',
  group_id: '2',
  keys: ['test2'],
  shell: '/bin/csh',
  directory: '/Users/test2',
  password: 'password',
  gecos: 'hoge',
  link_users: ['test1']
}

def create_or_update_user(user_attr)
  attrs = user_attr.merge({}) # 値が書き換わるためコピーしたハッシュを渡す
  user = User.find(name: attrs[:name])
  if user.nil?
    user = User.new(attrs)
    user.save!
  else
    User.update(attrs)
  end
end

describe 'GET /users' do
  before do
    [USER_1, USER_2].each { |attr| create_or_update_user(attr) }
  end

  context 'when no params' do
    it 'returns all users' do
      get '/users'
      expect(last_response).to be_ok
      users = JSON.parse(last_response.body)
      expect(users.size).to eq 2
    end
  end

  context 'when with name' do
    it 'returns user by name' do
      get '/users', { name: 'test1' }
      expect(last_response).to be_ok
      users = JSON.parse(last_response.body)
      expect(users.size).to eq 1
      user = users.first
      expect(user['name']).to eq USER_1[:name]
      expect(user['id']).to eq USER_1[:id].to_i
      expect(user['group_id']).to eq USER_1[:group_id].to_i
      expect(user['keys']).to include USER_1[:name]
      expect(user['shell']).to eq '/bin/bash'
      expect(user['directory']).to eq "/home/#{USER_1[:name]}"
      expect(user['gecos']).to eq ''
      expect(user['password']).to eq ''
    end
  end

  context 'when with id' do
    it 'returns user by id' do
      get '/users', { id: '2' }
      expect(last_response).to be_ok
      users = JSON.parse(last_response.body)
      expect(users.size).to eq 1
      user = users.first
      expect(user['name']).to eq USER_2[:name]
      expect(user['id']).to eq USER_2[:id].to_i
      expect(user['group_id']).to eq USER_2[:group_id].to_i
      expect(user['keys']).to include USER_1[:keys].first
      expect(user['keys']).to include USER_2[:keys].first
      expect(user['shell']).to eq '/bin/csh'
      expect(user['directory']).to eq '/Users/test2'
      expect(user['gecos']).to eq 'hoge'
      expect(user['password']).to eq 'password'
    end
  end
end
