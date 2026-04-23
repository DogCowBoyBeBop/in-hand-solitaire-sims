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
  #deckSize=${#myDeck[@]}
#   >&2 echo "moveCard deckSize: ${#myDeck[@]}" #DEBUG
#   if [ "${#myDeck[@]}" -gt 0 ] ; then
    myHand=( "${myDeck[0]}" "${myHand[@]}" )
    unset "myDeck[0]"
    myDeck=( "${myDeck[@]}" ) # reindex myDeck
#   fi
#   >&2 echo "myDeck: ${myDeck[@]}" #DEBUG
#   >&2 echo "myHand: ${myHand[@]}" #DEBUG
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
#   >&2 echo "disCardAsArr $@" #DEBUG
  IFS=' ' read -ra args <<< "$1"
  for theArg in "${args[@]}"; do
  >&2 echo "disCardAsArr theArg: $theArg" #DEBUG
    unset "myHand[$theArg]"
  done
  myHand=( "${myHand[@]}" ) # reindex
#   >&2 echo "disCardAsArr myHand@: ${myHand[@]}" #DEBUG
}

disCardAsArrName () { # discards named array
#   >&2 echo "disCardAsArr $@" #DEBUG
  local -n disarray=$1
  for theArg in "${disarray[@]}"; do
#   >&2 echo "disCardAsArrName theArg: $theArg" #DEBUG
    unset "myHand[$theArg]"
  done
  myHand=( "${myHand[@]}" ) # reindex
#   >&2 echo "disCardAsArr myHand@: ${myHand[@]}" #DEBUG
}

## CARD HAND EVALUATIONS

NORMALevalCards () { # NORMAL RULES
    # When there is a match of suit, discard the middle two
    # When there is a match of value, discard all four
    local isMatch="match"
    local numOfChains=0 # checking for chains
    while [ "$isMatch" = "match" ]; do
#         >&2 echo "doSuit: $doSuit" #DEBUG
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
#           isMatch="match" # not needed; sets myHand back to previous state
        elif [ "$suit1" == "$suit4" ];then
          disCard 1 2
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
          isMatch="match" # Go around again
        fi
      fi
    done
    actions=$(( $actions + $numOfChains ))
#     if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + $numOfChains )); fi
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
#     >&2 echo "numOfChains: $numOfChains" #DEBUG
#    >&2 echo "NORMALeval myHand ${#myHand[@]}: ${myHand[@]}" #DEBUG
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
#           isMatch="match" # not needed; sets myHand back to previous state
        elif [ "$suit1" == "$suit2" ] && [ "$suit1" == "$suit3" ] && [ "$suit1" == "$suit4" ];then
          disCard 0 1 2 3 
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
          numOfFlushes=$(( $numOfFlushes + 1 )) # tracking flushes
#           isMatch="match" # not needed; sets myHand back to previous state
        elif [ "$suit1" == "$suit4" ];then
          disCard 1 2
          numOfChains=$(( $numOfChains + 1 )) # checking for chains
          isMatch="match" # go around again
        fi
      fi
    done
    actions=$(( $actions + $numOfChains ))
#     if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + $numOfChains )); fi
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

CEevalCards () { # 
    # When there is a match of suit, discard the matching cards (instead of the middle two).
    # When there is a match of value, discard the middle two cards (instead of all four).
    # via curiousepic https://www.youtube.com/watch?v=ru9CwSDTDKw
    local isMatch="match"
    local numOfChains=0 # checking for chains
#     >&2 echo "CEeval myHand1: ${myHand[@]}" #DEBUG
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
#     if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + $numOfChains )); fi
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
#     >&2 echo "CEeval myHand2: ${myHand[@]}" #DEBUG
}



NNevalCards () { # NIDGI RULES
    # Discard middle two cards on matching rank OR suit
    local isMatch="match"
    local numOfChains=0 # checking for chains
    while [ "$isMatch" = "match" ]; do
#         >&2 echo "doSuit: $doSuit" #DEBUG
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
#     if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + $numOfChains )); fi
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

RMevalCards () { # ROYAL MARRIAGE RULES (Strict)
    # Discard middle one or two cards on matching rank OR suit
    local isMatch="match"
    local numOfChains=0 # checking for chains
#         >&2 echo "RMeval myHand1: ${myHand[*]}" #DEBUG
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
#         >&2 echo "RMeval myHand2: ${myHand[*]}" #DEBUG
#     >&2 echo "RMeval numOfChains/gameNumOfChains: $numOfChains / $gameNumOfChains" #DEBUG
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
#                 >&2 echo "QLeval disCard ${pairArr[@]}"
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
        #   >&2 echo "cards: $card1 & $card4" #DEBUG
        #   >&2 echo "suits: $suit1 & $suit4" #DEBUG
          if [ "$suit1" == "$suit3" ] || [ "$rank1" == "$rank3" ];then
#                 >&2 echo "QLeval disCard single ${myHand[1]}"
            disCard 1
            numOfChains=$(( $numOfChains + 1 )) # checking for chains
            isMatch="match" # Go around again
          fi
        else
#              >&2 echo "QLeval single card break" #DEBUG
           break
        fi
      done # while
    fi

    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
#           >&2 echo "gameNumOfChains/numOfChains: $gameNumOfChains & $numOfChains" #DEBUG
}

stable_core_TTTevalCards () { # Ten Twenty Thirty (Decade) Rules
    # If at least two contiguous cards add up to a decade (10, 20, or 30) discard them.
    local isMatch="match"
    local i=0
    local j=0
    local numOfChains=0 # checking for chains
#                 >&2 echo  ">>>>>> TTTeval myHand:  ${myHand[@]}" #DEBUG
                >&2 echo  "******* TTTeval myHand:  ${myHand[@]}" #DEBUG
      handSize="${#myHand[@]}"
#       cardSum=0
      cardArr=()
      while [ "$isMatch" = "match" ]; do
                >&2 echo  "  >--- TTTeval while loop ---<" #DEBUG
        isMatch=""
        cardSum=0
#           cardArr=()
#                 >&2 echo  ">>>TTTeval while #myHand / minHand: ${#myHand[@]} / $minHand" #DEBUG
#                 >&2 echo  ">>>TTTeval while myHand@: ${myHand[@]}" #DEBUG
        if [ $handSize -ge $minHand ]; then 
          ## CHECK FOR DECADES
          for ((i=0;i<handSize;i++));do # < because 0-index
#                 >&2 echo  "> > >TTTeval i loop \$i=${i} / <${handSize}" #DEBUG
#                 >&2 echo  "> > >TTTeval while for \$i / myHand[i]: $i / ${#myHand[i]}" #DEBUG
            cardSum=$(( $cardSum + ${myHand[i]} ))
#                 >&2 echo  "> > >TTTeval i loop cardSum:  $cardSum" #DEBUG
            if [ $cardSum -gt 30 ];then 
#                 >&2 echo  "> > > >TTTeval i loop break" #DEBUG
              break;
            elif ( [ $cardSum -eq 10 ] && [ ${#cardArr[@]} -gt 1 ] )|| [ $cardSum -eq 20 ] || [ $cardSum -eq 30 ] ; then
            >&2 echo  "   >>> TTTeval i loop cardSum/#cardArr: ${cardSum} / ${#cardArr[@]} > 1?" #DEBUG
              cardArr=() # assumption being more cards is better
              for ((j=0; j<=$i; j++));do
#                   cardArr+=( ${myHand[$j]} )
                  cardArr+=( $j )
#                 >&2 echo  "> > >TTTeval j loop cardArr:  ${cardArr[@]}" #DEBUG
              done # j loop
            fi
#             breakpoint
          done # i loop
          if [ ${#cardArr[@]} -gt 0 ]; then
#                 >&2 echo  ">>>TTTeval while cardArr: ${cardArr[@]}" #DEBUG
            >&2 echo  "   >>> TTTeval myHand:  ${myHand[@]}" #DEBUG
#             >&2 echo  ">>>>>> TTTeval cardSum:  $cardSum" #DEBUG
            >&2 echo  "   >>> TTTeval discarding:  ${cardArr[@]}" #DEBUG
            disCard "${cardArr[@]}"
            cardArr=()
            isMatch="match"
            handSize="${#myHand[@]}"
            numOfChains=$(( $numOfChains + 1 )) # 
          fi # cardArr
        fi # handsize
      done # while
    
#                 >&2 echo  ">>>>>> TTTeval out of while" #DEBUG

    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
#           >&2 echo "gameNumOfChains/numOfChains: $gameNumOfChains & $numOfChains" #DEBUG
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
#             >&2 echo  ">>>>>> TTTSeval myHand:  ${myHand[@]}" #DEBUG
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
    # Loops
   >&2 echo "--------> TTTSL myHand@: ${myHand[@]} " #DEBUG
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
#    >&2 echo "--------> TTTSL 2fwd: ${myHand[0]} + ${myHand[1]}  " #DEBUG
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
#    >&2 echo "--------> TTTL myHand@: ${myHand[@]} " #DEBUG
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
#             >&2 echo "------>TTTL forward start"
          for ((i=0;i<handSize;i++));do # < because 0-index
            cardSum=$(( $cardSum + ${myHand[i]} ))
            if [ $cardSum -gt 30 ];then 
#               isMatch=""
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
#             >&2 echo "---->TTTL backward iloop handSize / i: $handSize / $i"
#            >&2 echo "---->TTTL backward iloop theIndex / myHand[theIndex]: $theIndex / ${myHand[theIndex]}"
            cardSum=$(( $cardSum + ${myHand[theIndex]} ))
            cardArr+=($theIndex)
            if [ $cardSum -gt 30 ];then 
#               isMatch=""
              break;
            elif ( [ $cardSum -eq 10 ] && [ ${#cardArr[@]} -gt 1 ] )|| [ $cardSum -eq 20 ] || [ $cardSum -eq 30 ] ; then
              if [ "${#toDiscard[@]}" -le "${#cardArr[@]}" ]; then # -le prioritize looping to front
                toDiscard=("${cardArr[@]}") 
                isMatch="match"
              fi
            fi # cardSum
#            >&2 echo "---->TTTL backward iloop handSize / i take2: $handSize / $i"
#            breakpoint
          done # backwards i loop
          local lowCard=$(($theIndex + 1)) # ???
#            >&2 echo "--> ** TTTL lowCard/#myHand: $lowCard / ${#myHand[@]}" #DEBUG

          ## CHECK OVERLAPPING DECADES
#            >&2 echo "--> ** TTTL start overlap"
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
#           >&2 echo "--> ** TTTL overlap cardArr: ${cardArr[@]}"
#            >&2 echo "--> ** TTTL overlap i/myHand[i]: $i / ${myHand[i]}" #DEBUG
              if [ $cardSum -gt 30 ];then 
#                 isMatch=""
                break;
              elif ( [ $cardSum -eq 10 ] && [ ${#cardArr[@]} -gt 1 ] )|| [ $cardSum -eq 20 ] || [ $cardSum -eq 30 ] ; then
                if [ "${#toDiscard[@]}" -le "${#cardArr[@]}" ]; then # -le prioritize looping to front
                  toDiscard=("${cardArr[@]}") 
                  isMatch="match"
                fi
#            >&2 echo "--> ** TTTL overlap cardArr: ${cardArr[@]}"
              fi # cardSum
            done # i loop
#             if [ "${#toDiscard[@]}" -lt "${#cardArr[@]}" ]; then toDiscard=("${cardArr[@]}"); fi
          done # backwards c loop
          
          ## DISCARD
          if [ ${#toDiscard[@]} -gt 0 ]; then
#             disCard "${cardArr[@]}"
#           >&2 echo "-->TTTL toDiscard: ${toDiscard[@]}"
          disCardAsArrName toDiscard
#             cardArr=()
            isMatch="match"
            toDiscard=()
            handSize="${#myHand[@]}"
            numOfChains=$(( $numOfChains + 1 )) # 
          fi # cardArr
      done # while

    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
}

abandoned_TTTLevalCards () { # Ten Twenty Thirty (Decade) Strict Looping Rules
    # If TWO or THREE contiguous cards add up to a decade (10, 20, or 30) discard them.
    # Loops to front
#     local isMatch="match"
    local numOfChains=0 # checking for chains
#     local i=0
#     local j=0
    handSize="${#myHand[@]}"
    ##
    # Check up
    # Check from last backwards
      # 
    # First card and back 2
    # First two and back 1
    >&2 echo "--------> TTTL myHand@: ${myHand[@]} " #DEBUG
    cardArr=() # array of potential discards

#     ## CHECK UP ARRAY FOR DECADES
#     curSum=0 # current card total
#     curCard=0 # current card
#     curCardArr=() # array of current cards
#     while [ $curSum -lt 30 ] && [ $curCard -lt $handSize ]; do
#       curCardArr+=($curCard)
#       curSum=$(( $curSum + ${myHand[curCard]} ))
# #     >&2 echo ">> TTTL while curCard: $curCard " #DEBUG
#       if [ $curCard -gt 1 ] && \
#       ( [ $curSum -eq 10 ] || [ $curSum -eq 20 ] || [ $curSum -eq 30 ] ) ; then
# #         cardArr+=("${curCardArr[@]}") # add cards as potential discards
# #         cardArr=("${curCardArr[@]}") # replace current candidate
# #         cardArr[${#curCardArr[@]}]=("${curCardArr[@]}") # place by # of cards ## ERROR
#         cindex="${#curCardArr[@]}"
#       >&2 echo "--->TTTL cindex: $cindex"
# #         cardArr[$cindex]=("${curCardArr[*]}") # place by # of cards ## ERROR
#         cardArr[cindex]="${curCardArr[@]}" # place by # of cards ## ERROR
#       fi
#       curCard=$(( $curCard + 1 ))
#     done # WHILE
    
    ## CHECK BACKWARD
    curSum=0 # current card total
    curCard=0 # current card
    curIndex=0
    curCardCount=0 # count of cards looked at
    curCardArr=() # array of current cards
    while [ $curSum -lt 30 ] && [ $curCardCount -lt $handSize ]; do
      
      curCardArr+=($curCard)
#       >&2 echo "-->TTTL curSum / myHandcurIndex: $curSum / ${myHand[curIndex]}"
      curSum=$(( "$curSum" + "${myHand[$curIndex]}" ))
      # do stuff
      if [ ${#curCardArr[@]} -gt 1 ] && \
      ( [ $curSum -eq 10 ] || [ $curSum -eq 20 ] || [ $curSum -eq 30 ] ) ; then
        cindex="${#curCardArr[@]}"
      >&2 echo "-->TTTL if curIndex: $curIndex"
        cardArr[cindex]="${curCardArr[@]}" # place by # of cards ## ERROR
      >&2 echo "-->TTTL if curCardArr@: ${curCardArr[@]}"
      fi
      curCardCount=$(( $curCardCount + 1 ))
      curIndex=$(( $handSize - $curCardCount ))
      curCard="${myHand[$curIndex]}"
    done # while
      
    ## CHECK FORWARD FROM BACKWARD
    


    ## DO DISCARDS
    if [ ${#cardArr[@]} -gt 0 ]; then
      >&2 echo "-->TTTL end #curCardArr@: ${#curCardArr[@]}"
      disCard "${cardArr[@]}"
      disIndex="${#cardArr[@]}"
#       disCard "${cardArr[$disIndex]}"
#       disCard "${cardArr[$cindex]}"
      disCardAsArr "${cardArr[$cindex]}"
#       >&2 echo "--->TTTL cardArr ${disIndex}: ${cardArr[$disIndex]}"
#       >&2 echo "--->TTTL cardArr '2': ${cardArr[2]}"
#       >&2 echo "--->TTTL cardArr: ${cardArr[@]}"
      >&2 echo "--->TTTL cindex2: $cindex"
      
      cardArr=()
      isMatch="match"
      handSize="${#myHand[@]}"
      numOfChains=$(( $numOfChains + 1 )) # 
    fi # cardArr

    actions=$(( $actions + $numOfChains ))
    if [ "$numOfChains" -gt 1 ]; then gameNumOfChains=$(( $gameNumOfChains + 1 )); fi
#     breakpoint #DEBUG
}


playAGame () {
#  >&2 echo "PLAYAGAME $1" #DEBUG
  if [ "$1" = "rm" ] || [ "$1" = "ql" ]; then
    myDeck=( HC $(shuf -e "${deckRM[@]}") HD )
#     echo -e "\nTESTING\n^^^^^^^"; myDeck=(DC C2 C3 H9 H1 C9 DB) #TESTING QL=2 #DEBUG
  elif [ "$1" = "nn" ] || [ "$1" = "rmss" ]; then
    myDeck=( C1 $(shuf -e "${deckNN[@]}") S1 )
#     echo -e "\nTESTING\n^^^^^^^"; myDeck=( DB C2 C3 D8 S5 SB H3 C9 S1) #TESTING nn =3
  elif [ "$1" = "ttt" ] || [ "$1" = "ttts" ] || [ "$1" = "tttsl" ] || [ "$1" = "tttl" ]; then
    myDeck=( $(shuf -e "${deckTTT[@]}")  )
#     echo -e "\nTESTING\n^^^^^^^"; myDeck=( 2 10 8 10 2 9 10 7 10 3 2 3 4 10 3 6 4) #TESTING ttt =4 ttts=9 tttsl=7 tttl=1
#     echo -e "\nTESTING\n^^^^^^^"; myDeck=( 6 3 10 4 1 6  3) #TESTING tttsl =1 tttl=1
#     echo -e "\nTESTING\n^^^^^^^"; myDeck=( 1 3 1 3 5 10 2 4 7) #TESTING tttl =2
#     echo -e "\nTESTING\n^^^^^^^"; myDeck=( 1 7 7 8 7 7 5) #TESTING tttl =2
  else
    myDeck=( $(shuf -e "${deck52[@]}") )
#     echo -e "\nTESTING\n^^^^^^^"; myDeck=( DB C2 C7 C1 CA D9 D8 SB ) # (ce=4, flush=0)
#     echo -e "\nTESTING\n^^^^^^^"; myDeck=( DB C2 C3 D8 S5 SB H3 C9 ) #TESTING normal =2
  fi
  myHand=()
  gameNumOfChains=0 # checking for chains

  while [ ${#myDeck[@]} -gt 0 ]; do
    #while [ ${#myHand[@]} -lt 3 ]; do
    while [ ${#myHand[@]} -lt $(( $minHand - 1 )) ] && [ "${#myDeck[@]}" -gt 0 ] ; do
#     while [ ${#myHand[@]} -lt $minHand ] && [ "${#myDeck[@]}" -gt 0 ] ; do
#         >&2 echo "while myHand: ${#myHand[@]}"
         moveCard
#           if [ "${#myDeck[@]}" -gt 0 ] ; then moveCard; fi
    done
#     >&2 echo "--PAG after while myHand: ${myHand[@]}" #DEBUG
#     moveCard
if [ "${#myDeck[@]}" -gt 0 ] ; then moveCard; fi
#    >&2 echo "playAGame myHand ${#myHand[@]}: ${myHand[@]}" #DEBUG
#     >&2 echo "playAGame param 1: $1" #DEBUG
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
#           OLDQLevalCards
#           >&2 echo "myDeck case: ${myDeck[@]}" #DEBUG
#           >&2 echo "myHand case: ${myHand[@]}" #DEBUG
          ;;
      ttt) 
          TTTevalCards
#           >&2 echo "myDeck case: ${myDeck[@]}" #DEBUG
#           >&2 echo "myHand case: ${myHand[@]}" #DEBUG
          ;;
      ttts) 
          TTTSTRICTevalCards
#           >&2 echo "myDeck case: ${myDeck[@]}" #DEBUG
#           >&2 echo "myHand case: ${myHand[@]}" #DEBUG
          ;;
      tttsl) 
          TTTSLevalCards
#           >&2 echo "myDeck case: ${myDeck[@]}" #DEBUG
#           >&2 echo "myHand case: ${myHand[@]}" #DEBUG
          ;;
      tttl) 
          TTTLevalCards
#           >&2 echo "myDeck case: ${myDeck[@]}" #DEBUG
#           >&2 echo "myHand case: ${myHand[@]}" #DEBUG
          ;;
      *) >&2 echo -n ">>> playAGame is confused by ${1}"
          exit 1 ;;
    esac
  done
  # tracking chains
  chains=$(( $chains + $gameNumOfChains ))
#        >&2 echo "gameNumOfChains: $gameNumOfChains" #DEBUG
#        >&2 echo "chains: $chains" #DEBUG
  if [ $gameNumOfChains -gt $highChains ]; then highChains=$gameNumOfChains; fi
#         >&2 echo "gameNumOfChains: $gameNumOfChains" #DEBUG
#         >&2 echo "chains: $chains" #DEBUG
#         >&2 echo "highChains: $highChains" #DEBUG
#          >&2 echo ">> END HAND: ${myHand[@]}" #DEBUG
  score="${#myHand[@]}"
#   if [ $gameNumOfChains -gt 4 ]; then echo "currentDeck: ${currentDeck[@]}"; fi # DEBUG

}


  # set the game type
theGame='normal' # default
if [ -n "${1}" ]; then # number of games
  END="$1"
  if [ -n "${2}" ]; then # type of game
#    >&2 echo "1 2 param: ${1} ${2}" #DEBUG
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
# scoreTotal=0
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
#   >&2 echo " --- C COUNT=${c} ---" #DEBUG
  score=0
  playAGame $theGame
  if [ $score -lt $lowScore ]; then lowScore=$score; fi
  if [ $score -gt $highScore ]; then highScore=$score; fi
  scoreArr+=("$score")
  if [ $score = 0 ]; then perfectGames=$(( $perfectGames + 1 )); fi 
  if [ $score = 2 ]; then twoCardGames=$(( $twoCardGames + 1 )); fi 
  if [ $score -lt 4 ]; then decentGames=$(( $decentGames + 1 )); fi
#   [ "${i}" -gt 100 ] && break #DEBUG
#   breakpoint
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


# --REPORT--
# games = 200000 games with normal rules
# high score = 46
# low score = 0
# median score = 12
# perfect games = 1401  %.0070
# two card games = 9129  %.0456
# decent games = 10530  %.0526
# --tracking chains--
# actions = 3173758 %15.8687
# highest chain = 9
# chains = 431856 %2.1592
# --checking flushes--
# flushes = 0 %0
#   ---
# 
# real	17m37.510s
# user	12m47.283s
# sys	3m32.461s

# 👉 time ./1h3.sh 200000 flush
# --REPORT--
# games = 200000 games with flush rules
# high score = 48
# low score = 0
# median score = 10
# perfect games = 4852  %.0242
# two card games = 16339  %.0816
# decent games = 21191  %.1059
# --tracking chains--
# actions = 3049414 %15.2470
# highest chain = 8
# chains = 400452 %2.0022
# --checking flushes--
# flushes = 418277 %2.0913
#   ---
# 
# real	19m8.527s
# user	14m6.211s
# sys	3m42.495s

# 👉 time ./1h3.sh 200000 ce
# --REPORT--
# games = 200000 games with ce rules
# high score = 46
# low score = 2
# median score = 14
# perfect games = 0  %0
# two card games = 7241  %.0362
# decent games = 7241  %.0362
# --tracking chains--
# actions = 3782811 %18.9140
# highest chain = 10
# chains = 716694 %3.5834
# --checking flushes--
# flushes = 0 %0
#   ---
# 
# real	18m15.988s
# user	13m24.536s
# sys	3m33.571s

# --REPORT--
# games = 200000 games with rm rules
# high score = 35
# low score = 2
# median score = 6
# perfect games = 0  %0
# two card games = 65098  %.3254
# decent games = 69611  %.3480
# --tracking chains--
# actions = 5892469 %29.4623
# highest chain = 14
# chains = 1256099 %6.2804
# --checking flushes--
# flushes = 0 %0
#   ---
# 
# real	20m15.098s
# user	15m6.084s
# sys	3m53.447s
# --REPORT--
# games = 200000 games with rmss rules
# high score = 37
# low score = 2
# median score = 5
# perfect games = 0  %0
# two card games = 12875  %.0643
# decent games = 34037  %.1701
# --tracking chains--
# actions = 5835872 %29.1793
# highest chain = 13
# chains = 1254193 %6.2709
# --checking flushes--
# flushes = 0 %0
#   ---
# 
# real	20m16.257s
# user	15m7.043s
# sys	3m52.849s

# --REPORT--
# games = 200000 games with nn rules
# high score = 46
# low score = 2
# median score = 16
# perfect games = 0  %0
# two card games = 9595  %.0479
# decent games = 9595  %.0479
# --tracking chains--
# actions = 3543354 %17.7167
# highest chain = 10
# chains = 620795 %3.1039
# --checking flushes--
# flushes = 0 %0
#   ---
# 
# real	18m4.014s
# user	13m16.250s
# sys	3m29.838s

# --REPORT--
# games = 200000 games with ql rules
# high score = 44
# low score = 2
# median score = 13
# perfect games = 0  %0
# two card games = 7809  %.0390
# decent games = 7809  %.0390
# --tracking chains--
# actions = 5555559 %27.7777
# highest chain = 15
# chains = 1266830 %6.3341
# --checking flushes--
# flushes = 0 %0
#   ---
# 
# real	29m15.803s
# user	22m54.790s
# sys	4m48.943s

# --REPORT--
# games = 200000 games with ttt rules
# high score = 43
# low score = 0
# median score = 8
# perfect games = 33569  %.1678
# two card games = 11659  %.0582
# decent games = 64098  %.3204
# --tracking chains--
# actions = 2409265 %12.0463
# highest chain = 0
# chains = 0 %0
# --checking flushes--
# flushes = 0 %0
#   ---
# 
# real	422m25.400s
# user	111m16.233s
# sys	249m41.601s


# --REPORT--
# games = 200000 games with ttts rules
# high score = 52
# low score = 0
# median score = 29
# perfect games = 9  %0
# two card games = 4  %0
# decent games = 23  %.0001
# --tracking chains--
# actions = 0 %0
# highest chain = 0
# chains = 0 %0
# --checking flushes--
# flushes = 0 %0
#   ---
# 
# real	17m50.626s
# user	13m5.911s
# sys	3m28.018s

# games = 200000 games with tttsl rules
# high score = 39
# low score = 0
# median score = 5
# perfect games = 39908  %.1995
# two card games = 0  %0
# decent games = 66834  %.3341
# --tracking chains--
# actions = 2489025 %12.4451
# highest chain = 6
# chains = 171261 %.8563
# --checking flushes--
# flushes = 0 %0
#   ---
# 
# real	20m42.273s
# user	16m19.202s
# sys	3m5.590s

# --REPORT--
# games = 20000 games with tttl rules
# high score = 14
# low score = 0
# median score = 0
# perfect games = 13836  %.6918
# two card games = 0  %0
# decent games = 19225  %.9612
# --tracking chains--
# actions = 333624 %16.6812
# highest chain = 3
# chains = 2210 %.1105
# --checking flushes--
# flushes = 0 %0
#   ---
# 
# real	99m43.267s
# user	18m12.194s
# sys	59m29.525s
