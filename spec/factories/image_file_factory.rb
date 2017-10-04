FactoryGirl.define do
  factory :image_file do
    association :imageable, factory: :item
    file 'test.jpg'
    is_uploaded true
    upload_id 1


    after(:create) { |f|
      f.send(:raw_write_attribute, :file, 'test.jpg')
      f.save!
    }

    factory :image_file_collection do
      association :imageable, factory: :collection
    end

    factory :image_file_item do
      association :imageable, factory: :item
    end

  end
end
