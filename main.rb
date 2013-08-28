require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do
	def calculate_total(cards)
		hand = cards.map{|card| card[0]}

		total = 0
		hand.each do |val|
			if val == 'A'
				total += 11
			elsif val.to_i == 0
				total += 10
			else 
				total += val.to_i
			end

			hand.select{|ace| ace == 'A'}.count.times do
				break if total <= 21
				total -= 10
			end
		end
				
		total
	end

	def card_img(card) #['5','C']
		suit = case card[1]
			when 'C' then 'clubs'
			when 'D' then 'diamonds'
			when 'S' then 'spades'
			when 'H' then 'hearts'
		end

		value = card[0]
		if ['J','Q','K','A'].include?(value)
			value = case card[0]
				when 'J' then 'jack'
				when 'Q' then 'queen'
				when 'K' then 'king'
				when 'A' then 'ace'
			end

			"<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
		end
	end
end

before do
	@show_buttons = true
end

get '/' do 
	if session[:player_name]
		redirect '/game'
	else
		redirect '/new_player'
	end
end

get '/new_player' do
	erb :new_player
end


post '/new_player' do
	if params[:player_name].empty?
		@error = "A name is required!"
		halt erb(:new_player)
	end

	session[:player_name] = params[:player_name]
	#go to game
	redirect '/game'
end

get '/game' do
	#set initial values
		#set deck, deal cards
	#render template
	#deck
	suits = ['H','D','C','S']
	vals = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
	session[:deck] = vals.product(suits).shuffle!

	session[:dealer_cards] = []
	session[:player_cards] = []
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop



	erb :game
end


post '/game/player/hit' do
	session[:player_cards] << session[:deck].pop
	player_total = calculate_total(session[:player_cards])
	if player_total == 21
		"Congratulations! You hit Blackjack!!!"
		@show_buttons = false
	elsif player_total > 21
		@error = "Sorry, you busted!!"
		@show_buttons = false
	end
		erb :game
end

post '/game/player/stand' do
	@success = "You have chosen to stand"
	@show_buttons = false
	erb :game
end







































