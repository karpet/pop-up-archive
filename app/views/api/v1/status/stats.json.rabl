object false

node(:public_audio_dhms)  { total_public_duration_dhms }
node(:public_audio)  { total_public_duration.to_i }
node(:private_audio_dhms) { total_private_duration_dhms }
node(:private_audio) { total_private_duration.to_i }
