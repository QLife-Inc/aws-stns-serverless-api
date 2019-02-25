require 'spec_helper'
require 'logger'

LOGGER = Logger.new(STDOUT)

GROUP_1 = {
  name: 'test1',
  id: '1',
  users: ['test1']
}

GROUP_2 = {
  name: 'test2',
  id: '2',
  users: ['test2'],
  link_groups: ['test1']
}

def create_or_update_group(group_attr)
  attrs = group_attr.merge({}) # 値が書き換わるためコピーしたハッシュを渡す
  group = Group.find(name: attrs[:name])
  if group.nil?
    group = Group.new(attrs)
    group.save!
  else
    Group.update(attrs)
  end
end

describe 'GET /groups' do
  before do
    [GROUP_1, GROUP_2].each { |attr| create_or_update_group(attr) }
  end

  context 'when no params' do
    it 'returns all groups' do
      get '/groups'
      expect(last_response).to be_ok
      groups = JSON.parse(last_response.body)
      expect(groups.size).to eq 2
    end
  end

  context 'when with name' do
    it 'returns group by name' do
      get '/groups', { name: 'test1' }
      expect(last_response).to be_ok
      groups = JSON.parse(last_response.body)
      expect(groups.size).to eq 1
      group = groups.first
      expect(group['name']).to eq GROUP_1[:name]
      expect(group['id']).to eq GROUP_1[:id].to_i
      expect(group['users']).to include GROUP_1[:users].first
    end
  end

  context 'when with id' do
    it 'returns group by id' do
      get '/groups', { id: '2' }
      expect(last_response).to be_ok
      groups = JSON.parse(last_response.body)
      expect(groups.size).to eq 1
      group = groups.first
      expect(group['name']).to eq GROUP_2[:name]
      expect(group['id']).to eq GROUP_2[:id].to_i
      expect(group['users']).to include GROUP_1[:users].first
      expect(group['users']).to include GROUP_2[:users].first
    end
  end
end
