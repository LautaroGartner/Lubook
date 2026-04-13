require "faker"

puts "Clearing old data..."
Like.delete_all
Comment.delete_all
Post.delete_all
Follow.delete_all
Profile.delete_all
User.where.not(id: 1).delete_all  # keep your own account
puts "Backfilling missing profiles..."
User.where.missing(:profile).find_each { |u| u.create_profile!(display_name: u.username) }

puts "Creating users..."
users = 10.times.map do |i|
  User.create!(
    email: Faker::Internet.unique.email,
    password: "password12345",
    username: "user_#{i}_#{SecureRandom.hex(2)}",
    confirmed_at: Time.current
  )
end

puts "Creating follows..."
users.each do |u|
  (users - [ u ]).sample(3).each do |other|
    Follow.create!(requester: u, receiver: other, status: :accepted)
  rescue ActiveRecord::RecordInvalid
    next
  end
end

puts "Creating posts, comments, likes..."
users.each do |u|
  rand(2..5).times do
    post = u.posts.create!(body: Faker::Lorem.paragraph(sentence_count: 3))
    users.sample(3).each do |commenter|
      post.comments.create!(user: commenter, body: Faker::Lorem.sentence)
    end
    users.sample(4).each do |liker|
      Like.create!(user: liker, likeable: post) rescue nil
    end
  end
end

puts "Done! #{User.count} users, #{Post.count} posts, #{Comment.count} comments, #{Like.count} likes."
