#! /usr/bin/env bash
### DESCRIPTION


##### DEBUG
## Allows use of 'breakpoint'
## via https://stackoverflow.com/questions/69590411
shopt -s expand_aliases
alias breakpoint='
    while read -p"Debugging(Ctrl-d to exit)> " debugging_line
    do
        eval "$debugging_line"
    done'
##### END DEBUG

### FUNCTIONS
showHelp (){
  echo "Simulates the card game Shout Out NUMBER times."
  echo "Use: $(basename ${0}) NUMBER"
  exit
}

function getRandom () {
  # returns a random number up to that supplied in $1
  # this one sets variable "rando" instead
  declare -i power; declare -i aByte; declare -i top
  #TODO handle $1 == 1
  top="$1" # top of range
  aByte=256
  randRange=$aByte
  power=1
  until [ $randRange -ge $top ]; do
    power+=1; randRange=$(($aByte ** $power)) # raise to the next power
  done
  topMultiples=$(( $randRange / $top )) # Bash automatically floors division
  topRange=$(($top * $topMultiples))
  randx=$topRange # To ensure loop runs first time
  while (( randx >= $topRange )); do
      hex=`openssl rand -hex 2 | tr a-f A-F` # bc needs uppercase HEX
      randx=`echo "ibase=16; $hex" | bc` # convert from hex to decimal.
  done
  # randx now holds a random number between 0 and ($topRange -1)
  (( result = randx % $top )) # modulo is 'clean' now
  # result will be between 0 and $top -1, uniformly chosen.
  (( ++result ))   # result will be between 1 and $top
  rando="$result"
}

disCard () {
#   >&2 echo "disCard $@" #DEBUG
  for arg in "$@"; do
    unset "myDeck[$arg]"
  done
  myDeck=( "${myDeck[@]}" ) # reindex
}

# old_playAGame () { 
#     until [ ${#myDeck[@]} = 0 ]; do
# #   >&2 echo ""
#       getRandom 13
#       if [ $rando -eq ${myDeck[0]} ]; then
#         return 1
#       fi
#       disCard "${myDeck[0]}"
#     done
# }
playAGame () { 
    for i in {0..51}; do
      #getRandom 13 # this is dog slow
      #rando=$(( RANDOM % (MAX - MIN + 1) + MIN ))
      rando=128
      while [ $rando -gt 14 ]; do # this is to avoid bias
        rando=$(( RANDOM % 32 + 1 ))
      done
#   >&2 echo "playAGame mydeck[@]: ${myDeck[*]}"
#   >&2 echo "playAGame getRandom/mydeck[i]: $rando / ${myDeck[i]}"
      if [ $rando -eq ${myDeck[i]} ]; then
        return 1
      else
        score=$(( $score + 1 ))
      fi
#       disCard "${myDeck[0]}"
    done
}


suitless13=( 1 2 3 4 5 6 7 8 9 10 11 12 13) # suit doesn't matter, aces low
deck52=( "${suitless13[@]}" "${suitless13[@]}" "${suitless13[@]}" "${suitless13[@]}" )
rando=0 # used by getrandom
score=0 # num of cards before collision
lowScore=9000
highScore=0
scoreArr=()
perfectGames=0
flubbedGames=0
halfDeckGames=0

### MAIN
if [ -n "${1}" ]; then # number of games
  END="$1"
else
  showHelp
  exit
fi

for ((c=1;c<=END;c++)); do
#   >&2 echo " --- C COUNT=${c} ---" #DEBUG
  score=0
  myDeck=( $(shuf -e "${deck52[@]}") )
  playAGame
#   score="${#myDeck[0]}"
  if [ $score -lt $lowScore ] ; then lowScore=$score; fi
  if [ $score -gt $highScore ] ; then highScore=$score; fi
  scoreArr+=("$score")
  if [ $score = 52 ]; then perfectGames=$(( $perfectGames + 1 )); fi 
  if [ $score = 0 ]; then flubbedGames=$(( $flubbedGames + 1 )); fi 
  if [ $score -ge 26 ]; then halfDeckGames=$(( $halfDeckGames + 1 )); fi
#   [ "${i}" -gt 100 ] && break #DEBUG
#   breakpoint
done

# REPORT
echo "--REPORT--"
echo "games = $END games"
echo "high score = $highScore"
echo "low score = $lowScore"

sortArr=( $(printf '%s\n' "${scoreArr[@]}" | sort -n) ) # -n to sort numerically
median=$(( ${#scoreArr[@]} / 2 ))
echo "median score = ${sortArr[$median]}"
# >&2 echo "scale=4; $perfectGames / $END" #DEBUG
echo "perfect games = $perfectGames  %$(echo "scale=4; $perfectGames / $END" | bc)"
echo "flubbed games = $flubbedGames  %$(echo "scale=4; $flubbedGames / $END" | bc)"
echo "half deck games = $halfDeckGames  %$(echo "scale=4; $halfDeckGames / $END" | bc)"
 
# --REPORT--
# games = 200000 games
# high score = 52
# low score = 0
# median score = 9
# perfect games = 14338  %.0716
# two card games = 12376  %.0618
# decent games = 51285  %.2564
# 
# real	7m2.036s
# user	2m27.953s
# sys	3m11.708s