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
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image' style='border:1px solid black'/>"
  end

  def winner!(msg)
    @play_again = true
    @show_buttons = false
    session[:player_cash] = session[:player_cash] + session[:player_bet]
    @success = "<strong>#{session[:player_name]} wins</strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_buttons = false
    session[:player_cash] = session[:player_cash] - session[:player_bet]
    @error = "<strong>#{session[:player_name]} loses!!</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_buttons = false
    @success = "<strong>Looks like it's a tie!</strong> #{msg}"
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
  session[:player_cash] = 2000
  erb :new_player
end


post '/new_player' do
  if params[:player_name].empty?
    @error = "A name is required!"
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  #go to game
  redirect '/bet'
end

get '/bet' do
  session[:player_bet] = nil
  erb :bet
end

post '/bet' do
  if session[:player_cash] == 0
    @error = "Oops, you're all out of money! Click 'New Game' to reload!"
    halt erb(:bet)
  end
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_cash]
    @error = "Bet amount cannot be greater than what you have ($#{session[:player_cash]})"
    halt erb(:bet)
  else #happy path
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end

get '/game' do

  session[:turn] = session[:player_name]

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
    winner!("#{session[:player_name]} hit Blackjack!")

    redirect '/game/dealer'
  elsif player_total == 21 && session[:player_cards].count == 2
    @success = "Congratulations! You hit Blackjack"
    @show_buttons = false
    redirect '/game/dealer'
  elsif player_total > 21
    loser!("It looks like you busted at #{player_total}! You lose $#{session[:player_bet]}")
  end

    erb :game  
end

post '/game/player/stand' do
  @success = "You have chosen to stand"
  @show_buttons = false
  redirect '/game/dealer'
end


get '/game/dealer' do
  session[:turn] = 'dealer'
  @show_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == 21
    loser!("Dealer hit 21! You lose $#{session[:player_bet]}")
  elsif dealer_total > 21
    winner!("Dealer busted out at #{dealer_total}!! You win $#{session[:player_bet]}!!")
  elsif dealer_total >= 17 
    #dealer stays
    redirect '/game/who_won'
  else
    #dealer hits
    @show_dealer_hit = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/who_won' do
  @show_buttons = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    @error = "Sorry, You Lost $#{session[:player_bet]}!"
    loser!("You chose to stand at #{player_total} and 
      the dealer has #{dealer_total}. You lose $#{session[:player_bet]}")
  elsif player_total > dealer_total
    winner!("You Win $#{session[:player_bet]}!!")
  else
    tie!("Keep your money!")
  end

  erb :game
end

get '/game_over' do
  erb :game_over
end

get '/about' do
  erb :about
end

get '/rules' do
  erb :rules
end





































