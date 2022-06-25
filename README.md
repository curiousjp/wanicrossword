# WaniCrossword

WaniCrossword builds a simple crossword out of your 'burned' items on the [WaniKani](https://wanikani.com/) Japanese Spaced Repetition System.  A hosted copy is available on GitHub Pages at https://curiousjp.github.io/wanicrossword/#/ 

## Getting Started

You will require an API key to make use of this program - a read-only one is recommended. This video will quickly run you through the process of using the software:
[![Watch the video](https://img.youtube.com/vi/KIeGs8zCucM/0.jpg)](https://youtu.be/KIeGs8zCucM)

In short, once the program has loaded, click the key icon at the top right and you will be prompted for your API key. Wait a little while and click refresh, and you will be greeted with a crossword based on your burned items. If API retrieval is still ongoing, you will instead get a crossword made up of a message explaining this.

You can select a typing location either with your mouse, or by clicking on clues in the two lists to the right. Text can be entered in romaji, without an IME, and the program will attempt to convert it to either hiragana or katakana, depending on the required answer. It will also attempt to spill digraphs like ぎょ to the next relevant input box. If the entered text is in the appropriate format for the required answer, it will also attempt to automatically advance to the next box, and clear it if it judges it appropriate to do so.

The crossword can be re-laid out by clicking the 🔁 button at the top right. This does not require a re-fetch from WaniKani, so it should be quick. The scoreboard icon will tell you how many cells you have filled correctly, and will clear any that are wrong.

## Issues

API keys are not stored persistently. Navigation is clunky and would be improved by arrow key or backspace support.  There may be other navigation bugs lurking in the code.

There is little customisability for users. It should be possible to limit a puzzle either by number of clues or side length to allow for shorter play.

## Acknowledgements

This program uses Jeroen Meijer's dart port of WanaKana, [kana_kit](https://pub.dev/packages/kana_kit). Thank you, Jeroen.

## Links

[Thread on the WaniKani community forums.](https://community.wanikani.com/t/web-app-wanicrossword-crosswords-from-burned-items/57515)