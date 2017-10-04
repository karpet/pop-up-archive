attributes :id
attributes :name
#attributes :amara_team

child :users do |u|
  attributes :id, :name, :role
end

node(:invited_users) do |org|
  u = []
  org.invited_users.each do |user|
    u.push({ id: user.id, name: user.name })
  end
  u
end
