FactoryGirl.define do
  factory :transcript do
    transient do
      timed_texts_count 2
    end

    # not-null but orphaned by default
    audio_file_id 0

    after(:create) do |transcript, evaluator|
      FactoryGirl.create_list(:timed_text, evaluator.timed_texts_count, transcript: transcript)
    end

  end
end
