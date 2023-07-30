#!/bin/bash

PSQL="psql -A -U freecodecamp -d number_guess -t -c"

START_GUESSING_GAME () {
  RANDOM_NUMBER=$(($RANDOM % 1000 + 1))

  GUESSING_GAME $1 $RANDOM_NUMBER 1 "Guess the secret number between 1 and 1000:"
}

GUESSING_GAME () {
    echo -e "\n$4"
    read GUESS

    if [[ $GUESS =~ ^[0-9]+$ ]]
    then
      if [ $2 -lt $GUESS ]
      then
        GUESSING_GAME $1 $2 $(($3+1)) "It's lower than that, guess again:"
      
        return
      fi

      if [ $2 -gt $GUESS ]
      then
        GUESSING_GAME $1 $2 $(($3+1)) "It's higher than that, guess again:"
      
        return
      fi

      ADD_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, number, attempts_for_guessing) VALUES($1, $2, $3)")

      if [[ $ADD_GAME_RESULT == "INSERT 0 1" ]]
      then
        echo "You guessed it in $3 tries. The secret number was $2. Nice job!"
      else
        echo "Sorry! Something went wrong on adding game to DB."
      fi
    else
      GUESSING_GAME $1 $2 $3 "That is not an integer, guess again:"
    fi
}

echo -e "\n~~~~~ Number guessing Game ~~~~~\n"

echo -e "Enter your username:"
read USERNAME

USER_ID=$($PSQL "SELECT user_id FROM users WHERE name='$USERNAME'")

if [[ -z $USER_ID ]]
then
  ADD_USER_RESULT=$($PSQL "INSERT INTO users(name) VALUES('$USERNAME')")

  if [[ $ADD_USER_RESULT == "INSERT 0 1" ]]
  then
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE name='$USERNAME'")

    echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."

    START_GUESSING_GAME $USER_ID
  else
    echo "Sorry! Something went wrong on adding user to DB."
  fi
else
  GAMES=$($PSQL "SELECT count(*), min(attempts_for_guessing) FROM games WHERE user_id=$USER_ID")

  echo "$GAMES" | while IFS="|" read COUNT BEST_GAME
  do
    echo "Welcome back, $USERNAME! You have played $COUNT games, and your best game took $BEST_GAME guesses."  
  done 

  START_GUESSING_GAME $USER_ID
fi
