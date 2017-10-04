# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

transcribers = Transcriber.create([
  {
    name: 'google_voice',
    url:  '',
    cost_per_min: 0,
    description: 'unofficial google voice api',
  },
  {
    name: 'speechmatics',
    url:  'http://speechmatics.com/',
    cost_per_min: 62,  # 1000ths of a dollar
    description: 'speechmatics',
  },
  {
    name: 'voicebase',
    url:  'http://voicebase.com/',
    cost_per_min: 50,  # 1000ths of a dollar
    description: 'voicebase',
  },
])

# collections require a valid owner (billable_to)
user = User.new({name: 'seed user', email: 'seeduser@nosuchemail.org', password: 'sekrit'})
user.save!

collections = Collection.create([{"creator_id"=> user.id, "title" => "Test Collection", "description" => "This collection will show you how collections work."}, {"creator_id"=> user.id, "title" => "A Second Collection", "default_storage_id" => 1, "items_visible_by_default" => true, }])
item = Item.new("title" => "Lost Weekend Video finds new ways to entertain in the digital age")
item.description = "A couple on an evening stroll down Valencia Street comes to a stop outside Lost Weekend Video. They’re peering in through the big front window."
item.collection_id = collections.first.id
item.save!

file = AudioFile.new()
file.item_id = item.id
file.file = "LostWeekend.mp3"
file.original_file_url = "http://archive.org/download/lost-weekend-video-finds-new-ways-to-entertain-in.EU5iLJ.popuparchive.org/WEB.LostWeekend.mp3"
file.identifier = "http://cpa.ds.npr.org/kalw/audio/2014/05/WEB.LostWeekend.mp3"
file.transcoded_at = "2014-06-04 19:39:20"
file.user_id = user.id
file.save!

transcript = Transcript.new()
transcript.audio_file_id = file.id
transcript.language = "en-US"
transcript.save!

timed_texts = [
  {
    end_time: "5.5",
    start_time: "0.0",
    text: "this is cross currents I'm heading out Baba Booey live in the age of Tweety"
  },
  {
    end_time: "10.5",
    start_time: "5.0",
    text: "reading houses but it was long ago that we were living without the internet"
  },
  {
    end_time: "15.5",
    start_time: "10.0",
    text: "if you're old enough you can probably remember how you had to"
  },
  {
    end_time: "20.5",
    start_time: "15.0",
    text: "had to leave your house to buy anything if you wanted to watch your favorite shows"
  },
  {
    end_time: "25.5",
    start_time: "20.0",
    text: "show you how to actually turn on your TV when it is aired and if you wanted to enjoy a move"
  },
  {
    end_time: "30.5",
    start_time: "25.0",
    text: "play movie at home and had to get up go out and do the special kind of store"
  },
  {
    end_time: "35.5",
    start_time: "30.0",
    text: "on the Lincoln Street in San Francisco door still exist"
  },
  {
    end_time: "40.5",
    start_time: "35.0",
    text: "people walking be like how this places yeah you like that"
  },
  {
    end_time: "45.5",
    start_time: "40.0",
    text: "they give him and then you bring it back and get it"
  },
  {
    end_time: "50.5",
    start_time: "45.0",
    text: "the whole court is one of the owners of Lost Weekend video on demand"
  },
  {
    end_time: "55.5",
    start_time: "50.0",
    text: "Mannford video rentals have plummeted Interco workers have found other ways to keep their patrons"
  },
  {
    end_time: "60.5",
    start_time: "55.0",
    text: "patrons entertained KLW Zadran dealing paid a visit to the store to see how it"
  },
  {
    end_time: "65.5",
    start_time: "60.0",
    text: "how its your fault a couple on an evening stroll Danville NC"
  },
  {
    end_time: "70.5",
    start_time: "65.0",
    text: "Valencia Street just came to a stop outside Lost Weekend video their period"
  },
  {
    end_time: "75.5",
    start_time: "70.0",
    text: "peering into the big front window is a kind of interesting and wanted to check it out"
  },
  {
    end_time: "80.5",
    start_time: "75.0",
    text: "haven't seen a video store in a long time but Abel Martinez these days"
  },
  {
    end_time: "85.5",
    start_time: "80.0",
    text: "I watch a lot of pirated movies well at least he's honest"
  },
  {
    end_time: "90.5",
    start_time: "85.0",
    text: "and he's not alone almost half of all Americans have illegally downloaded a show"
  },
  {
    end_time: "95.5",
    start_time: "90.0",
    text: "show or movie that wanted to watch many of those people probably used to go to video stores"
  },
  {
    end_time: "100.5",
    start_time: "95.0",
    text: "Lake Martinez partner Maria Turner lloveras on MyLife website about 5 years ago"
  },
  {
    end_time: "105.5",
    start_time: "100.0",
    text: "now she only goes if she can't find something online do you go to the video store"
  },
  {
    end_time: "110.5",
    start_time: "105.0",
    text: "can't find a Netflix video stores he's kind of rain"
  },
  {
    end_time: "115.5",
    start_time: "110.0",
    text: "how to write the number of independent video stores in the country has fallen by over half since 2000"
  },
  {
    end_time: "120.5",
    start_time: "115.0",
    text: "1004 and last year at the national champ walk Buster close all its stores"
  },
  {
    end_time: "125.5",
    start_time: "120.0",
    text: "Lost Weekend video of Management Advisor weekend"
  },
  {
    end_time: "130.5",
    start_time: "125.0",
    text: "unequivocal night you might walk in and see a movie playing on the two big TVs inside"
  },
  {
    end_time: "135.5",
    start_time: "130.0",
    text: "tonight is basketball about it doesn't People Miller around the Isles looking at the road"
  },
  {
    end_time: "140.5",
    start_time: "135.0",
    text: "Rhoda DVDs and VHS tapes. Find out the place seems welcoming"
  },
  {
    end_time: "145.5",
    id: 4382807,
    start_time: "140.0",
    text: "and co-founder David Hawkins says that was the original point in my mind"
  },
  {
    end_time: "150.5",
    id: 4382808,
    start_time: "145.0",
    text: "was how do you start it wasnt so large with intimidating"
  },
  {
    end_time: "155.5",
    id: 4382809,
    start_time: "150.0",
    text: "Norse old Nick show that it was frustrating"
  },
  {
    end_time: "160.5",
    id: 4382810,
    start_time: "155.0",
    text: "you don't started back in the late nineties Hawkins and two friends were all working in the music industry"
  },
  {
    end_time: "165.5",
    id: 4382811,
    start_time: "160.0",
    text: "but wanted to do something different co-owner Christie Colcord had an idea"
  },
  {
    end_time: "170.5",
    id: 4382812,
    start_time: "165.0",
    text: "suggested that we may be opening a store if you could sleep late and it was just"
  },
  {
    end_time: "175.5",
    id: 4382813,
    start_time: "170.0",
    text: "just talked about movies all day soon after that they started stockpiling their favorite color"
  },
  {
    end_time: "180.5",
    id: 4382814,
    start_time: "175.0",
    text: "indie films in storing them at her place I had the biggest apartment on Albion Street"
  },
  {
    end_time: "185.5",
    id: 4382815,
    start_time: "180.0",
    text: "in my whole living room just became like every bookshelf every pie was full of"
  },
  {
    end_time: "190.5",
    id: 4382816,
    start_time: "185.0",
    text: "VHS to take a blood test when I got to a couple thousand titles"
  },
  {
    end_time: "195.5",
    id: 4382817,
    start_time: "190.0",
    text: "the opened up shot cool card says they were a lot fewer businesses on Valencia at the time"
  },
  {
    end_time: "200.5",
    id: 4382818,
    start_time: "195.0",
    text: "the time but they did have competition a couple of a small video stores tower in black by"
  },
  {
    end_time: "205.5",
    id: 4382819,
    start_time: "200.0",
    text: "blockbuster nearby cool card says Lost Weekend filled a perticular need"
  },
  {
    end_time: "210.5",
    id: 4382820,
    start_time: "205.0",
    text: "at the time it was a lot of artists and filmmakers and old San Francisco"
  },
  {
    end_time: "215.5",
    id: 4382821,
    start_time: "210.0",
    text: "princess cut types so there are people who are really in the movies on media culture"
  },
  {
    end_time: "220.5",
    id: 4382822,
    start_time: "215.0",
    text: "everything about the kind of songs that we went to get in pharmacy"
  },
  {
    end_time: "225.5",
    id: 4382823,
    start_time: "220.0",
    text: "stop it you can get it the other the chains even when Netflix first came on the scene"
  },
  {
    end_time: "230.5",
    id: 4382824,
    start_time: "225.0",
    text: "Cortes Lost Weekend wasn't really sweating it take army was booming so people just did both"
  },
  {
    end_time: "235.5",
    id: 4382825,
    start_time: "230.0",
    text: "Netflix and Bethany Mota wasn't streaming so they would have a Netflix account"
  },
  {
    end_time: "240.5",
    id: 4382826,
    start_time: "235.0",
    text: "how to put stuff in aq in the lake Fassbender movie that showed up they would not be in the mood for that night cuz it was"
  },
  {
    end_time: "245.5",
    id: 4382827,
    start_time: "240.0",
    text: "it was more like in the theory they want to watch it you know but when the economy collapsed in 2008"
  },
  {
    end_time: "250.5",
    id: 4382828,
    start_time: "245.0",
    text: "people had to choose one or the other David Hawkins says many of Lost Weekend"
  },
  {
    end_time: "255.5",
    id: 4382829,
    start_time: "250.0",
    text: "weekends diehard customers lost their jobs and left the city and in the old days"
  },
  {
    end_time: "260.5",
    id: 4382830,
    start_time: "255.0",
    text: "we were a recession proof business because you know spending $3 on a video about it"
  },
  {
    end_time: "265.5",
    id: 4382831,
    start_time: "260.0",
    text: "cheap dates you can have but today people can watch as many movies as they want for less than 10"
  },
  {
    end_time: "270.5",
    id: 4382832,
    start_time: "265.0",
    text: "a month so they had to think of new ways to bring people into the store"
  },
  {
    end_time: "275.5",
    id: 4382833,
    start_time: "270.0",
    text: " "
  },
  {
    end_time: "280.5",
    id: 4382834,
    start_time: "275.0",
    text: "about 2 years ago last weekend started holding movie screenings"
  },
  {
    end_time: "285.5",
    id: 4382835,
    start_time: "280.0",
    text: "meanings in the stores basement which way does the syndicave their old red"
  },
  {
    end_time: "290.5",
    id: 4382836,
    start_time: "285.0",
    text: "red velvet movie theater seats down there which hold a cozy 20 people are so"
  },
  {
    end_time: "295.5",
    id: 4382837,
    start_time: "290.0",
    text: "teen after the movie nice weekend what stores honor started experimenting with lightener"
  },
  {
    end_time: "300.5",
    id: 4382838,
    start_time: "295.0",
    text: "live entertainment stand up comedy improv"
  },
  {
    end_time: "305.5",
    id: 4382839,
    start_time: "300.0",
    text: "there used to be just a few comedy shows in month"
  },
  {
    end_time: "310.5",
    id: 4382840,
    start_time: "305.0",
    text: "but they were such a hit there now if you a week and the Beast Maga tree label"
  },
  {
    end_time: "315.5",
    id: 4382841,
    start_time: "310.0",
    text: "relay bold the cynic cave people pay 5 to 10 show to watch local community"
  },
  {
    end_time: "320.5",
    id: 4382842,
    start_time: "315.0",
    text: "comedians and occasionally big name"
  },
  {
    end_time: "325.5",
    id: 4382843,
    start_time: "320.0",
    text: "APRI of my favorite 3 songs by Ace of Base never know what you might see"
  },
  {
    end_time: "330.5",
    id: 4382844,
    start_time: "325.0",
    text: "Blair short talk is in the audience tonight she says she comes to comedy show seeking something she can't get it"
  },
  {
    end_time: "335.5",
    id: 4382845,
    start_time: "330.0",
    text: "get it home it's pretty much the energy that you get from the performers"
  },
  {
    end_time: "340.5",
    id: 4382846,
    start_time: "335.0",
    text: "because you know I might be scripted it might be improvised Mun anything can have"
  },
  {
    end_time: "345.5",
    id: 4382847,
    start_time: "340.0",
    text: "can happen and I think nothing can replace my ID what are your three favorite"
  },
  {
    end_time: "350.5",
    id: 4382848,
    start_time: "345.0",
    text: "the original purpose of the shows with 2 drawers"
  },
  {
    end_time: "355.5",
    id: 4382849,
    start_time: "350.0",
    text: "to draw in more customers and make a little extra cash but the performances have also created"
  },
  {
    end_time: "360.5",
    id: 4382850,
    start_time: "355.0",
    text: "create a place for people to come together in real time and space an alternative to watching"
  },
  {
    end_time: "365.5",
    id: 4382851,
    start_time: "360.0",
    text: "watching something alone in your room on a laptop David Hawkins wants to remind people that"
  },
  {
    end_time: "370.5",
    id: 4382852,
    start_time: "365.0",
    text: "all that is actually can be fun to do things the old fashioned way no matter what netflix says"
  },
  {
    end_time: "375.5",
    id: 4382853,
    start_time: "370.0",
    text: "u-haul on campaigns I can only be so happy ever after the video stored in those pesky videos"
  },
  {
    end_time: "380.5",
    id: 4382854,
    start_time: "375.0",
    text: "video stores that are just like we're not the dentist you know we're not the DMV"
  },
  {
    end_time: "385.5",
    id: 4382855,
    start_time: "380.0",
    text: "can see the effects of technology on our lives just by looking at on Valencia Street of course"
  },
  {
    end_time: "390.5",
    id: 4382856,
    start_time: "385.0",
    text: "horse relief that to a movie feels a little like the invasion of Body Snatchers at times were you"
  },
  {
    end_time: "395.5",
    id: 4382857,
    start_time: "390.0",
    text: "is a street a completely dead car they never used to be"
  },
  {
    end_time: "400.5",
    id: 4382858,
    start_time: "395.0",
    text: "or is just a very different feeling but not all change is bad"
  },
  {
    end_time: "405.5",
    id: 4382859,
    start_time: "400.0",
    text: "according to Christy call card Blanchester talking to be what it was a 1995 Franklin"
  },
  {
    end_time: "410.5",
    id: 4382860,
    start_time: "405.0",
    text: "5 people used to poop in our plan our son step you know so I thought it was a dream time but"
  },
  {
    end_time: "415.5",
    id: 4382861,
    start_time: "410.0",
    text: "but what we can continue to serve as is like this reminder"
  },
  {
    end_time: "420.5",
    id: 4382862,
    start_time: "415.0",
    text: "founder of the community that blunt Street used to have in terms of like artists musicians"
  },
  {
    end_time: "425.5",
    id: 4382863,
    start_time: "420.0",
    text: "creative people and people who wanted to talk to each other"
  },
  {
    end_time: "430.5",
    id: 4382864,
    start_time: "425.0",
    text: "other and didn't want to sit in the Box to get that though the conversation"
  },
  {
    end_time: "435.5",
    id: 4382865,
    start_time: "430.0",
    text: "are the movies are live entertainment you might just have to leave your house"
  },
  {
    end_time: "440.5",
    id: 4382866,
    start_time: "435.0",
    text: "39 in San Francisco I'm Audrey dealing for cross currents"
  },
  {
    end_time: "445.5",
    id: 4382867,
    start_time: "440.0",
    text: "do on Wednesday thank you"
  },
  {
    end_time: "447.921633",
    id: 4382868,
    start_time: "445.0",
    text: " "
  }
]

timed_texts.each{|text|
  tt = TimedText.new()
  tt.transcript_id = transcript.id
  tt.end_time = text[:end_time]
  tt.start_time =  text[:start_time]
  tt.text = text[:text]
  tt.save!
}

transcript.start_time = timed_texts.first[:start_time]
transcript.end_time = timed_texts.last[:end_time]
transcript.save!
file.duration = timed_texts.last[:end_time]
file.save!

item2 = Item.new("title" => "Happy holidays!", "description" => "Today, on a very special Cory Doctorow podcast, the podcasting debut of Ms Poesy Emmeline Fibonacci Nautilus Taylor Doctorow!. This item belongs to: audio/podcast_corydoctorow. This item has files of the following types: Metadata, VBR MP3")
item2.collection_id = collections.first.id
item2.save!

public_item1 = Item.new(:title => "hooray for the red white and blue", :description => "I am a yankee doodle dandy", :tags => ['blue', 'green', 'red'])
public_item1.collection_id = collections[1].id
public_item1.is_public = true
public_item2 = Item.new(:title => "hooray for the green black and orange", :description => "a real life nephew of my uncle sam", :tags => ['blue', 'green', 'red'])
public_item2.collection_id = collections[1].id
public_item2.is_public = true
public_item1.save!
public_item2.save!
