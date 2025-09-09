
Bash функции для записи звука из браузера через ffmpeg с PulseAudio
Запись в mp3 с возможностью выбора моно/стерео, битрейта (k32-k320),
длительности (форматы 33m, 1h48m32s и т.п.), CBR/VBR (переменный/постоянный битрейт),
и с вводом имени файла.
После записи автоматически откроется папка с файлом.

Функции:
   rec [duration] [битрейт] [c]    - стерео, VBR по умолчанию
   recm [duration] [битрейт] [c]   - моно, VBR по умолчанию
   recc [duration] [битрейт]       - стерео, постоянный битрейт (CBR)
   recmc [duration] [битрейт]       - моно, постоянный битрейт (CBR)

Где параметры опциональны:
   duration - продолжительность записи (например 33m, 1h48m32s). Без параметра - до Ctrl+C
   битрейт - k32, k64, k96, k128, k160, k192, k224, k320 (по умолчанию k192)
   c - recmc recc   - флаг для CBR (постоянный битрейт). Если не указан, считается VBR

Примеры:
   recm           моно, 192k VBR, до остановки
   rec 33m k320   стерео, 320k VBR, 33 минуты
   recmc 1h48m32s k192    моно, 192k CBR, 1ч48м32с
   recc 15m k128  стерео, 128k CBR, 15 минут
   recmc          моно, 192k CBR, до Ctrl+C
Примеры для алиасов
в .bashrc добавь:

if [ -f ~/.bash_aliases_recorder ]; then
    . ~/.bash_aliases_recorder
fi

Содержимое .bash_aliases_recorder
Подключаем файл с функциями (чтобы функции были доступны)
source $HOME/.scripts/media/recorder/ffmpg_audio_recorder.sh

Алиасы для функций (чтобы вызывать коротко из терминала)
alias rec='rec'
alias recm='recm'
alias recc='recc'
alias recmc='recmc'
alias rec3='rec k320'
alias rec32='recmc k32'
alias rec64='recmc k64'
