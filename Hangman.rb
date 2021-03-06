class Hangman
	MAX_TURNS = 8

	attr_accessor :current_turn, :reveal_string, :secret_word_length
	attr_reader :checker, :guesser, :guessed_letters

	def initialize(checker, guesser)
		@checker = checker
		@guesser = guesser
		@reveal_string = "_"
		@current_turn = 1
		@guessed_letters = []
		@secret_word_length = 0
	end

	def run
		game_start

		until over?
			guessed_letter = guesser.get_guess(self.guessed_letters, secret_word_length, self.reveal_string)
			guessed_indices = checker.check_guess(guessed_letter, self.guessed_letters)
			self.guessed_letters << guessed_letter
			self.current_turn += 1 unless guessed_indices.length > 0
			self.reveal_string = update_reveal_string(guessed_letter, guessed_indices)
			puts self.reveal_string
			puts
		end

		puts won? ? "#{guesser.name} wins!" : "#{guesser.name} lost!"
	end

	def game_start
		checker.pick_secret_word
		self.secret_word_length = checker.secret_word_length
		puts "#{secret_word_length} letters"
		puts
		self.reveal_string = "_" * secret_word_length
		puts self.reveal_string
	end

	def draw

	end

	def over?
		return true if won?
		return true if self.current_turn == MAX_TURNS
		false
	end

	def won?
		self.reveal_string.split(//).none? {|char| char == '_' }
	end

	def update_reveal_string(letter, indices)
		reveal_as_arr = reveal_string.split(//)
		indices.each {|index| reveal_as_arr[index] = letter}
		reveal_as_arr.join
	end
end

class ComputerPlayer

	DICTIONARY = File.readlines("dictionary.txt").map(&:chomp)

	attr_accessor :name, :secret_word_length, :secret_word, :possible_guesses

	def initialize(name = "Hangmanbot")
		@name = name
		@possible_guesses = DICTIONARY.dup
	end

	def pick_secret_word
		self.secret_word = DICTIONARY.sample
		puts "Secret word - #{secret_word} - SHHHHH!!!!"
		self.secret_word_length = secret_word.length
		puts "Secret word has been chosen."
	end

	def get_guess(guessed_letters, secret_word_length, reveal_string)
		pg = self.possible_guesses

		pg = pg.select {|word| word.length == secret_word_length }

		new_poss_guesses = pg.dup

		pg.select do |word|
			word.split(//).each_with_index do |char, index|
				if reveal_string[index] != char && reveal_string[index] != '_'
					new_poss_guesses.delete(word)
				end
			end
		end

		pg = new_poss_guesses

		letter_freq = Hash.new(0)

		pg.each do |word|
			word.split(//).each do |letter|
				letter_freq[letter] += 1
			end
		end

		letter_freq.delete_if {|key, value| guessed_letters.include?(key)}
		letter_freq = letter_freq.to_a

		letter_freq_sorted = letter_freq.sort {|char1, char2| char2[1] <=> char1[1]}
		most_freq_letter = letter_freq_sorted.first
		most_freq_letter[0]
	end



	def check_guess(guess, guessed_letters)
		guessed_indices = []

		if guessed_letters.any? {|letter| letter == guess}
			puts "You guessed that already!"
			puts
		else
			self.secret_word.split('').each_with_index do |letter, i|
				guessed_indices << i if letter == guess
			end
		end

		guessed_indices
	end

end

class HumanPlayer

	attr_accessor :name, :secret_word_length

	def initialize(name = "Tom")
		@name = name
	end

	def pick_secret_word
		print "Please enter the length of your secret word: "
		word_len = 0

		until word_len.is_a?(Integer) && word_len > 0
			begin
				word_len = Integer(gets)
			rescue ArgumentError
				puts "Make sure your input is valid"
			end
		end

		puts "The length of the secret word is #{secret_word_length}."
		self.secret_word_length = word_len
	end

	def get_guess(guessed_letters, secret_word_length, reveal_string)
		puts "Already guessed: #{guessed_letters.sort.inspect}"

		print "Guess a letter: "
    begin
		  guess = gets.chomp
      raise IllegalArgumentError if ('a'..'z').none? {|letter| letter == guess}
    rescue IllegalArgumentError
      puts "Try Again"
      retry
    end

    guess
	end

	def check_guess(guess, guessed_letters)
		guessed_indices = []
		good_input = false

		until good_input

			if guessed_letters.any? {|letter| letter == guess}
				return []
			else
				puts "Does your word contain #{guess}? Enter Y or N"
				input = gets.chomp.upcase

				if input == 'Y'
					good_input = true
					guessed_indices = get_guess_indices(guess)
				elsif input == 'N'
					good_input = true
					return []
				else
					puts "Sorry I didn't understand that!"
					good_input = false
				end
			end
		end

		guessed_indices
	end

	def get_guess_indices(guess)
		puts "Where in your word does #{guess} occur?"
		puts "Enter comma separated numbers e.g. 1,4,7 (Start at index 1)"
		input = gets.chomp
		input.split(',').map{|num| num.to_i - 1}
	end
end

class IllegalArgumentError < StandardError
end

p1 = ComputerPlayer.new
p2 = HumanPlayer.new

game = Hangman.new(p2, p1)
game.run