
#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo -e "~~ Number Guessing Game ~~\n"

RANDOM_NUMBER=$(( 1 + RANDOM % 1000 ))
echo $RANDOM_NUMBER

echo "Enter your username:"
read USERNAME

# Validate username length
while [[ ${#USERNAME} -lt 3 ]]; do
  echo "Username must be at least 3 characters. Please try again:"
  read USERNAME
done

# Check if the user exists
USER_DATA=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username='$USERNAME' LIMIT 1")

if [[ -z $USER_DATA ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL)")
else
  # Returning user
  IFS="|" read DB_USERNAME GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  echo "Welcome back, $DB_USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start the guessing game
NUMBER_OF_GUESSES=0
echo -e "\nGuess the secret number between 1 and 1000:"

while read SECRET_NUMBER; do
  # Validate input
  if [[ ! $SECRET_NUMBER =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((NUMBER_OF_GUESSES++))

  if [[ $SECRET_NUMBER -eq $RANDOM_NUMBER ]]; then
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

    # Update games_played and best_game
    if [[ -n $USER_DATA ]]; then
      GAMES_PLAYED=$((GAMES_PLAYED + 1))
      if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
        BEST_GAME=$NUMBER_OF_GUESSES
        UPDATE_STATS=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED, best_game=$BEST_GAME WHERE username='$USERNAME'")
      else
        UPDATE_STATS=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE username='$USERNAME'")
      fi
    else
      UPDATE_STATS=$($PSQL "UPDATE users SET games_played=1, best_game=$NUMBER_OF_GUESSES WHERE username='$USERNAME'")
    fi

    break
    # compare the input the and random and output if input lower or higher and the random number
  elif [[ $SECRET_NUMBER -gt $RANDOM_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done
