#! /usr/bin/env bash
# Trying to simulate 1 Hand Solitaire
# Version 3

clubs=(C1 C2 C3 C4 C5 C6 C7 C8 C9 CA CB CC CD)
diamonds=(D1 D2 D3 D4 D5 D6 D7 D8 D9 DA DB DC DD)
hearts=(H1 H2 H3 H4 H5 H6 H7 H8 H9 HA HB HC HD)
spades=(S1 S2 S3 S4 S5 S6 S7 S8 S9 SA SB SC SD)
deck52=( "${clubs[@]}" "${diamonds[@]}" "${hearts[@]}" "${spades[@]}" )

royalMarriageHearts=(H1 H2 H3 H4 H5 H6 H7 H8 H9 HA HB) # Add HC (Queen) and HD (King) later
deckRM=( "${clubs[@]}" "${diamonds[@]}" "${royalMarriageHearts[@]}" "${spades[@]}" )

NNclubs=(C2 C3 C4 C5 C6 C7 C8 C9 CA CB CC CD)
NNspades=(S2 S3 S4 S5 S6 S7 S8 S9 SA SB SC SD) # Add C1 and S1 (Aces) in later
deckNN=( "${NNclubs[@]}" "${diamonds[@]}" "${hearts[@]}" "${NNspades[@]}" )

suitless10=( 1 2 3 4 5 6 7 8 9 10 10 10 10) # for decades, suit doesn't matter faces are 10
deckTTT=( "${suitless10[@]}" "${suitless10[@]}" "${suitless10[@]}" "${suitless10[@]}" )


##### DEBUG https://stackoverflow.com/questions/69590411/can-i-put-a-breakpoint-in-shell-script
shopt -s expand_aliases
alias breakpoint='
    while read -p"Debugging(Ctrl-d to exit)> " debugging_line
    do
        eval "$debugging_line"
    done'
##### END DEBUG

### FUNCTIONS
showHelp (){
  echo "$BASH_VERSION" #DEBUG
  echo '
Use: $(basename ${0}) NUMBER [TYPE]
  Where NUMBER is the number of games to play (e.g. 20000)
  and TYPE is the game type:
    normal - (default) standard one hand solitaire rules
    flush -  normal, plus four of a suit is discarded
    ce - curiousepic rules
    nn - Nidgi Novgorod rules
    rm - Royal Marriage rules
    rmss - Royal Marriage Same Sex rules (end cards match in rank)
    ql - Queen and Her Lad rules
' ; exit 0
}


moveCard () { # moves one card from front of deck to front of hand
    myHand=( "${myDeck[0]}" "${myHand[@]}" )
    unset "myDeck[0]"
    myDeck=( "${myDeck[@]}" ) # reindex myDeck
}

disCard () {
  >&2 echo "disCard $@" #DEBUG
  for arg in "$@"; do
  >&2 echo "disCard arg $arg" #DEBUG
    unset "myHand[$arg]"
  done
  myHand=( "${myHand[@]}" ) # reindex
}

disCardAsArr () { # discards "stringified" array
  IFS=' ' read -ra args <<< "$1"
  for theArg in "${args[@]}"; do
    unset "myHand[$theArg]"
  done
  myHand=( "${myHand[@]}" ) # reindex
}

disCardAsArrName () { # discards named array
  local -n disarray=$1
  for theArg in "${disarray[@]}"; do
    unset "myHand[$theArg]"
  done
  myHand=( "${myHand[@]}" ) # reindex
}

## CARD HAND EVALUATIONS

NORMALevalCards () { # NORMAL RULES
    # When there is a match of suit, discard the middle two
    # When there is a match of value, discard all four
    local isMatch="match"
    local numOfChains=0 # checking for chains
    while [ "$isMatch" = "match" ]; do
          isMatch=""
      if [ "${#myHand[@]}" -gt 3 ]; then
          card1=${myHand[0]}
          card4=${myHand[3]}
          rank1=${card1:1:1}
          rank4=${card4:1:1}
          suit1=${card1:0:1}
          suit4=${card4:0:1}

        if [ "$rank1" == "$rank4" ];then
          disCard 0 1 2 3 
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
        elif [ "$suit1" == "$suit4" ];then
          disCard 1 2
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
          isMatch="match" # Go around again
        fi
      fi
    done
    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

FLUSHevalCards () { 
    # Like normal, but adds that if four cards, next to each other,
    # are the same suit, all four are also removed.
    local isMatch="match"
    local numOfChains=0 # checking for chains

    while [ "$isMatch" = "match" ]; do
          isMatch=""
      if [ "${#myHand[@]}" -gt 3 ]; then
          card1=${myHand[0]}
          card2=${myHand[1]}
          card3=${myHand[2]}
          card4=${myHand[3]}
          suit1=${card1:0:1}
          suit2=${card2:0:1}
          suit3=${card3:0:1}
          suit4=${card4:0:1}
          rank1=${card1:1:1}
          rank4=${card4:1:1}
        if [ "$rank1" == "$rank4" ];then
          disCard 0 1 2 3 
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
        elif [ "$suit1" == "$suit2" ] && [ "$suit1" == "$suit3" ] && [ "$suit1" == "$suit4" ];then
          disCard 0 1 2 3 
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
          numOfFlushes=$(( $numOfFlushes + 1 )) # tracking flushes
        elif [ "$suit1" == "$suit4" ];then
          disCard 1 2
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
          isMatch="match" # go around again
        fi
      fi
    done
    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

CEevalCards () { # 
    # When there is a match of suit, discard the matching cards (instead of the middle two).
    # When there is a match of value, discard the middle two cards (instead of all four).
    # via curiousepic https://www.youtube.com/watch?v=ru9CwSDTDKw
    local isMatch="match"
    local numOfChains=0 # checking for chains
    while [ "$isMatch" = "match" ]; do
          isMatch=""
      if [ "${#myHand[@]}" -gt 3 ]; then
          card1=${myHand[0]}
          card4=${myHand[3]}
          rank1=${card1:1:1}
          rank4=${card4:1:1}
          suit1=${card1:0:1}
          suit4=${card4:0:1}

        if [ "$rank1" == "$rank4" ];then
          disCard 1 2 
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
          isMatch="match" 
        elif [ "$suit1" == "$suit4" ];then
          disCard 0 3
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
          isMatch="match" 
        fi
      fi
    done
    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

NNevalCards () { # NIDGI RULES
    # Discard middle two cards on matching rank OR suit
    local isMatch="match"
    local numOfChains=0 # checking for chains
    while [ "$isMatch" = "match" ]; do
          isMatch=""
      if [ "${#myHand[@]}" -gt 3 ]; then
          card1=${myHand[0]}
          card4=${myHand[3]}
          rank1=${card1:1:1}
          rank4=${card4:1:1}
          suit1=${card1:0:1}
          suit4=${card4:0:1}
        if [ "$rank1" == "$rank4" ] || [ "$suit1" == "$suit4" ];then
          disCard 1 2
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
          isMatch="match" # Go around again
        fi
      fi
    done
    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

RMevalCards () { # ROYAL MARRIAGE RULES (Strict)
    # Discard middle one or two cards on matching rank OR suit
    local isMatch="match"
    local numOfChains=0 # checking for chains
    while [ "$isMatch" = "match" ]; do
          isMatch=""
      if [ "${#myHand[@]}" -gt 2 ]; then
        card1=${myHand[0]}
        card3=${myHand[2]}
        card4=${myHand[3]}
        suit1=${card1:0:1}
        suit3=${card3:0:1}
        suit4=${card4:0:1}
        rank1=${card1:1:1}
        rank3=${card3:1:1}
        rank4=${card4:1:1}
        if [ "$rank1" == "$rank4" ] || [ "$suit1" == "$suit4" ];then
          disCard 1 2 
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
          isMatch="match" # go around again
        elif [ "$rank1" == "$rank3" ] || [ "$suit1" == "$suit3" ];then
          disCard 2
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
          isMatch="match" # Go around again
        fi
      fi
    done
    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

QLevalCards () { # Queen and Her Lad Rules
    # If the top card and the _third_ match in rank or suit, discard the _middle one_.
    # If the top card and the fourth match in rank or suit, **and** the middle two _also_ match in rank or suit, discard the middle pair.
    # If the top card and a matching card are separated by a run of contiguous pairs (in rank or suit) the intervening pairs are discarded.
    local isMatch="match"
    local numOfChains=0 # checking for chains
    if [ ${#myHand[@]} -ge 3 ]; then 
      while [ "$isMatch" = "match" ]; do
        isMatch=""
        ## CHECK FOR RUN OF PAIRS
        if [ ${#myHand[@]} -ge 4 ]; then
          card1=${myHand[0]}
          rank1=${card1:1:1}
          suit1=${card1:0:1}
          handNum=${#myHand[@]}
          pairArr=()
          for ((i=1;i<=handNum;i+=2)); do
            firstCard=${myHand[$i]}
            firstSuit=${firstCard:0:1}
            firstRank=${firstCard:1:1}
            secondCard=${myHand[$i+1]}
            secondSuit=${secondCard:0:1}
            secondRank=${secondCard:1:1}
            if [ "$firstSuit" == "$secondSuit" ] || [ "$firstRank" == "$secondRank" ];then 
              pairArr+=( "$i" $(( $i+1 )) )
            else 
              break
            fi
          done
          if [ ${#pairArr[@]} -gt 0 ]; then # Check for matching card
            card2=${myHand[$i]}
            rank2=${card2:1:1}
            suit2=${card2:0:1}
            if [ "$suit1" == "$suit2" ] || [ "$rank1" == "$rank2" ];then 
              disCard "${pairArr[@]}"
              localChain=$(( ${#pairArr[@]} / 2 )) # Each pair is one action
              numOfChains=$(( $numOfChains + $localChain )) # checking for chains
              isMatch="match" # go around again
            fi
          fi
        fi
        ## CHECK FOR SINGLE CARD
        if [ ${#myHand[@]} -ge 3 ]; then # return; fi
          card3=${myHand[2]}
          rank3=${card3:1:1}
          suit3=${card3:0:1}
          if [ "$suit1" == "$suit3" ] || [ "$rank1" == "$rank3" ];then
            disCard 1
            numOfChains=$(( $numOfChains + 1 )) # checking for chains
            isMatch="match" # Go around again
          fi
        else
           break
        fi
      done # while
    fi

    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

stable_core_TTTevalCards () { # Ten Twenty Thirty (Decade) Rules
    # If at least two contiguous cards add up to a decade (10, 20, or 30) discard them.
    local isMatch="match"
    local i=0
    local j=0
    local numOfChains=0 # checking for chains
      handSize="${#myHand[@]}"
      cardArr=()
      while [ "$isMatch" = "match" ]; do
                >&2 echo  "  >--- TTTeval while loop ---<" #DEBUG
        isMatch=""
        cardSum=0
        if [ $handSize -ge $minHand ]; then 
          ## CHECK FOR DECADES
          for ((i=0;i<handSize;i++));do # < because 0-index
            cardSum=$(( $cardSum + ${myHand[i]} ))
            if [ $cardSum -gt 30 ];then 
              break;
            elif ( [ $cardSum -eq 10 ] && [ ${#cardArr[@]} -gt 1 ] )|| [ $cardSum -eq 20 ] || [ $cardSum -eq 30 ] ; then
            >&2 echo  "   >>> TTTeval i loop cardSum/#cardArr: ${cardSum} / ${#cardArr[@]} > 1?" #DEBUG
              cardArr=() # assumption being more cards is better
              for ((j=0; j<=$i; j++));do
                  cardArr+=( $j )
              done # j loop
            fi
          done # i loop
          if [ ${#cardArr[@]} -gt 0 ]; then
            disCard "${cardArr[@]}"
            cardArr=()
            isMatch="match"
            handSize="${#myHand[@]}"
            numOfChains=$(( $numOfChains + 1 )) # 
          fi # cardArr
        fi # handsize
      done # while

    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

TTTevalCards () { # Ten Twenty Thirty (Decade) Rules
    # If at least two contiguous cards add up to a decade (10, 20, or 30) discard them.
    local isMatch="match"
    local i=0
    local j=0
    local numOfChains=0 # checking for chains
      handSize="${#myHand[@]}"
      cardArr=()
      while [ "$isMatch" = "match" ]; do
        isMatch=""
        cardSum=0
        if [ $handSize -ge $minHand ]; then 
          ## CHECK FOR DECADES
          for ((i=0;i<handSize;i++));do # < because 0-index
            cardSum=$(( $cardSum + ${myHand[i]} ))
            if [ $cardSum -gt 30 ];then 
              break;
            elif ( [ $cardSum -eq 10 ] && [ ${#cardArr[@]} -gt 1 ] )|| [ $cardSum -eq 20 ] || [ $cardSum -eq 30 ] ; then
              cardArr=() # assumption being more cards is better
              for ((j=0; j<=$i; j++));do
                  cardArr+=( $j )
              done # j loop
            fi
          done # i loop
          ## CHECK LOOPS TBD
          if [ ${#cardArr[@]} -gt 0 ]; then
            disCard "${cardArr[@]}"
            cardArr=()
            isMatch="match"
            handSize="${#myHand[@]}"
            numOfChains=$(( $numOfChains + 1 )) # 
          fi # cardArr
        fi # handsize
      done # while

    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

TTTSTRICTevalCards () { # Ten Twenty Thirty (Decade) Rules
    # If TWO or THREE contiguous cards add up to a decade (10, 20, or 30) discard them.
    local isMatch="match"
    local i=0
    local j=0
    local numOfChains=0 # checking for chains
    local disArr=() # array of potential discards
      handSize="${#myHand[@]}"
      ## CHECK FORWARD
      twoValue=$(( ${myHand[0]} + ${myHand[1]} ))
      if [ $twoValue -eq 10 ] || [ $twoValue -eq 20 ] || [ $twoValue -eq 30 ] ; then
        disArr=
      fi
      threeValue=$(( $twoValue + ${myHand[2]} ))
      if [ $threeValue -eq 10 ] || [ $threeValue -eq 20 ] || [ $threeValue -eq 30 ] ; then
        disCard 0 1 2
      elif [ $twoValue -eq 10 ] || [ $twoValue -eq 20 ] || [ $twoValue -eq 30 ] ; then
        disCard 0 1
      fi
    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

TTTSLevalCards () { # Ten Twenty Thirty (Decade) Rules
    # If TWO or THREE contiguous cards add up to a decade (10, 20, or 30) discard them.
    local isMatch="match"
    local numOfChains=0 # checking for chains
    local toDiscard=()
    while [ "$isMatch" = "match" ]; do
      isMatch=""
      handSize="${#myHand[@]}"
      ## CHECK FORWARD
      # check 2 forward
      if [ $handSize -lt 2 ]; then return 1; fi
      twoValue=$(( ${myHand[0]} + ${myHand[1]} ))
      if [ $twoValue -eq 10 ] || [ $twoValue -eq 20 ] || [ $twoValue -eq 30 ] ; then
        toDiscard=(0 1)
      fi
      if [ $handSize -ge 3 ]; then
        lastCard=$((${#myHand[@]} - 1))
        # check 2 backward
        twoValue=$(( ${myHand[0]} + ${myHand[lastCard]} ))
        if [ $twoValue -eq 10 ] || [ $twoValue -eq 20 ] || [ $twoValue -eq 30 ] ; then
          toDiscard=($lastCard 0)
        fi
        # check 3 forward
        threeValue=$(( ${myHand[0]} + ${myHand[1]} + ${myHand[2]} ))
        if [ $threeValue -eq 10 ] || [ $threeValue -eq 20 ] || [ $threeValue -eq 30 ] ; then
          toDiscard=(0 1 2)
        fi
        # check 3 middle
        threeValue=$(( ${myHand[0]} + ${myHand[1]} + ${myHand[lastCard]} ))
        if [ $threeValue -eq 10 ] || [ $threeValue -eq 20 ] || [ $threeValue -eq 30 ] ; then
          toDiscard=($lastCard 0 1)
        fi
      fi
      if [ $handSize -ge 4 ]; then
        # check 3 back
        penultCard=$((${#myHand[@]} - 2))
        threeValue=$(( ${myHand[penultCard]} + ${myHand[lastCard]} + ${myHand[0]} ))
        if [ $threeValue -eq 10 ] || [ $threeValue -eq 20 ] || [ $threeValue -eq 30 ] ; then
          toDiscard=($penultCard $lastCard 0)
        fi
      fi # >=4
      # DISCARD AND RESET
       if [ ${#toDiscard[@]} -gt 0 ]; then
   >&2 echo "------> TTTSL toDiscard@: ${toDiscard[@]} " #DEBUG
          disCardAsArrName toDiscard
          toDiscard=()
          isMatch="match"
          handSize="${#myHand[@]}"
          numOfChains=$(( $numOfChains + 1 )) # 
        fi # cardArr
   done # while

    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

TTTLevalCards () { # Ten Twenty Thirty (Decade) Rules
    # If at least two contiguous cards add up to a decade (10, 20, or 30) discard them.
    # Loops
    local isMatch="match"
    local i=0
    local j=0
    local c=0
    local numOfChains=0 # checking for chains
      handSize="${#myHand[@]}"
      while [ "$isMatch" = "match" ] && [ $handSize -ge $minHand ]; do
        isMatch=""
        cardSum=0
        cardArr=()
        local toDiscard=()
          ## CHECK FORWARD DECADES
          for ((i=0;i<handSize;i++));do # < because 0-index
            cardSum=$(( $cardSum + ${myHand[i]} ))
            if [ $cardSum -gt 30 ];then 
              break;
            elif ( [ $cardSum -eq 10 ] && [ ${#cardArr[@]} -gt 1 ] )|| [ $cardSum -eq 20 ] || [ $cardSum -eq 30 ] ; then
              cardArr=() # assumption being more cards is better
              for ((j=0; j<=$i; j++));do
                  cardArr+=( $j )
              done # j loop
            fi # cardSum
          done # i loop
          local highCard=$i
          if [ "${#toDiscard[@]}" -lt "${#cardArr[@]}" ]; then toDiscard=("${cardArr[@]}"); fi
          ## CHECK BACKWARD DECADES
          cardSum=0
          cardArr=()
          for ((i=0;i<handSize;i++));do # < because 0-index
            if [ $i -gt 0 ]; then theIndex=$(( $handSize - $i )); else theIndex=$i; fi
            cardSum=$(( $cardSum + ${myHand[theIndex]} ))
            cardArr+=($theIndex)
            if [ $cardSum -gt 30 ];then 
              break;
            elif ( [ $cardSum -eq 10 ] && [ ${#cardArr[@]} -gt 1 ] )|| [ $cardSum -eq 20 ] || [ $cardSum -eq 30 ] ; then
              if [ "${#toDiscard[@]}" -le "${#cardArr[@]}" ]; then # -le prioritize looping to front
                toDiscard=("${cardArr[@]}") 
                isMatch="match"
              fi
            fi # cardSum
          done # backwards i loop
          local lowCard=$(($theIndex + 1)) # ???
          ## CHECK OVERLAPPING DECADES
          cardArr=()
          for ((c=lowCard;c<handSize;c++));do # Repeat for lower numbers
            cardSum=0
            cardArr=()
            for ((i=0;i<handSize;i++));do # basically do forward decade searches
              theIndex=$(( $c + $i ))
              if [ $theIndex -ge $handSize ]; then theIndex=$(( $theIndex - $handSize ))
              fi
              cardSum=$(( $cardSum + ${myHand[theIndex]} ))
              cardArr+=($theIndex)
              if [ $cardSum -gt 30 ];then 
                break;
              elif ( [ $cardSum -eq 10 ] && [ ${#cardArr[@]} -gt 1 ] )|| [ $cardSum -eq 20 ] || [ $cardSum -eq 30 ] ; then
                if [ "${#toDiscard[@]}" -le "${#cardArr[@]}" ]; then # -le prioritize looping to front
                  toDiscard=("${cardArr[@]}") 
                  isMatch="match"
                fi
              fi # cardSum
            done # i loop
          done # backwards c loop
          ## DISCARD
          if [ ${#toDiscard[@]} -gt 0 ]; then
          disCardAsArrName toDiscard
            isMatch="match"
            toDiscard=()
            handSize="${#myHand[@]}"
            numOfChains=$(( $numOfChains + 1 )) # 
          fi # cardArr
      done # while

    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}




playAGame () {
  if [ "$1" = "rm" ] || [ "$1" = "ql" ]; then
    myDeck=( HC $(shuf -e "${deckRM[@]}") HD )
  elif [ "$1" = "nn" ] || [ "$1" = "rmss" ]; then
    myDeck=( C1 $(shuf -e "${deckNN[@]}") S1 )
  elif [ "$1" = "ttt" ] || [ "$1" = "ttts" ] || [ "$1" = "tttsl" ] || [ "$1" = "tttl" ]; then
    myDeck=( $(shuf -e "${deckTTT[@]}")  )
  else
    myDeck=( $(shuf -e "${deck52[@]}") )
  fi
  myHand=()
  gameNumOfChains=0 # checking for chains

  while [ ${#myDeck[@]} -gt 0 ]; do
    while [ ${#myHand[@]} -lt $(( $minHand - 1 )) ] && [ "${#myDeck[@]}" -gt 0 ] ; do
         moveCard
    done
if [ "${#myDeck[@]}" -gt 0 ] ; then moveCard; fi
    case "$1" in
      normal)
          NORMALevalCards ;;
      flush)
          FLUSHevalCards ;;
      ce)
          CEevalCards ;;
      nn)
          NNevalCards ;;
      rm) #exit #DEBUG
          RMevalCards ;;
      rmss) #exit #DEBUG
          RMevalCards ;;
      ql) 
          QLevalCards
          ;;
      ttt) 
          TTTevalCards
          ;;
      ttts) 
          TTTSTRICTevalCards
          ;;
      tttsl) 
          TTTSLevalCards
          ;;
      tttl) 
          TTTLevalCards
          ;;
      *) >&2 echo -n ">>> playAGame is confused by ${1}"
          exit 1 ;;
    esac
  done
  # tracking chains
  chains=$(( $chains + $gameNumOfChains ))
  if [ $gameNumOfChains -gt $highChains ]; then highChains=$gameNumOfChains; fi
  score="${#myHand[@]}"
}


  # set the game type
theGame='normal' # default
if [ -n "${1}" ]; then # number of games
  END="$1"
  if [ -n "${2}" ]; then # type of game
    #theGame="${2,,}" # lowercase ### bad sub?
    theGame="${2}"
  fi
else
  showHelp
  exit
fi

  # minimum hand size before evaluation can happen
if [ "$2" = "ql" ] || [ "$2" = "rm" ] ; then
  minHand=3
elif [ "$2" = "ttt" ] || [ "$2" = "ttts" ] || [ "$2" = "tttsl" ] || [ "$2" = "tttl" ] ; then
  minHand=2
else
  minHand=4
fi
  # scoring vars
score=0
highScore=0
lowScore=9000
scoreArr=()
perfectGames=0
twoCardGames=0
decentGames=0
  # tracking chains
actions=0
chains=0
gameNumOfChains=0
highChains=0
  # tracking flushes
numOfFlushes=0


for ((c=1;c<=END;c++)); do
  score=0
  playAGame $theGame
  if [ $score -lt $lowScore ]; then lowScore=$score; fi
  if [ $score -gt $highScore ]; then highScore=$score; fi
  scoreArr+=("$score")
  if [ $score = 0 ]; then perfectGames=$(( $perfectGames + 1 )); fi 
  if [ $score = 2 ]; then twoCardGames=$(( $twoCardGames + 1 )); fi 
  if [ $score -lt 4 ]; then decentGames=$(( $decentGames + 1 )); fi
done

# REPORT
echo "--REPORT--"
echo "games = $END games with $theGame rules"
echo "high score = $highScore"
echo "low score = $lowScore"

sortArr=( $(printf '%s\n' "${scoreArr[@]}" | sort -n) ) # -n to sort numerically
median=$(( ${#scoreArr[@]} / 2 ))
echo "median score = ${sortArr[$median]}"
echo "perfect games = $perfectGames  %$(echo "scale=4; $perfectGames / $END" | bc)"
echo "two card games = $twoCardGames  %$(echo "scale=4; $twoCardGames / $END" | bc)"
echo "decent games = $decentGames  %$(echo "scale=4; $decentGames / $END" | bc)"
echo "--tracking chains--"
echo "actions = $actions %$(echo "scale=4; $actions / $END" | bc)"
echo "highest chain = $highChains"
echo "chains = $chains %$(echo "scale=4; $chains / $END" | bc)"
echo "--checking flushes--"
echo "flushes = $numOfFlushes %$(echo "scale=4; $numOfFlushes / $END" | bc)"
echo "  ---"


