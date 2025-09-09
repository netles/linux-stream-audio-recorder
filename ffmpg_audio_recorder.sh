##
## Bash функции для записи звука из браузера через ffmpeg с PulseAudio
## Запись в mp3 с возможностью выбора моно/стерео, битрейта (k32-k320),
## длительности (форматы 33m, 1h48m32s и т.п.), CBR/VBR (переменный/постоянный битрейт),
## и с вводом имени файла.
## После записи автоматически откроется папка с файлом.
##
## Функции:
##   rec [duration] [битрейт] [c]    - стерео, VBR по умолчанию
##   recm [duration] [битрейт] [c]   - моно, VBR по умолчанию
##   recc [duration] [битрейт]       - стерео, постоянный битрейт (CBR)
##   recmc [duration] [битрейт]       - моно, постоянный битрейт (CBR)
##
## Где параметры опциональны:
##   duration - продолжительность записи (например 33m, 1h48m32s). Без параметра - до Ctrl+C
##   битрейт - k32, k64, k96, k128, k160, k192, k224, k320 (по умолчанию k192)
##   c        - флаг для VBR (переменный битрейт). Если не указан, считается CBR для recc и recmc
##
## Примеры:
##   recm           # моно, 192k VBR, до остановки
##   rec 33m k320   # стерео, 320k VBR, 33 минуты
##   recmc 1h48m32s k192    # моно, 192k CBR, 1ч48м32с
##   recc 15m k128  # стерео, 128k CBR, 15 минут
##   recmc          # моно, 192k CBR, до Ctrl+C
## Примеры для алиасов
# в .bashrc добавь:
# 
# if [ -f ~/.bash_aliases_recorder ]; then
#     . ~/.bash_aliases_recorder
# fi
# 
# Содержимое .bash_aliases_recorder
# # Подключаем файл с функциями (чтобы функции были доступны)
# source $HOME/.scripts/media/recorder/ffmpg_audio_recorder.sh
# 
# # Алиасы для функций (чтобы вызывать коротко из терминала)
# alias rec='rec'
# alias recm='recm'
# alias recc='recc'
# alias recmc='recmc'
# alias rec3='rec k320'
# alias rec32='recmc k32'
# alias rec64='recmc k64'


record_dir="$HOME/Music/stream"
mkdir -p "$record_dir"

get_seconds() {
  if [[ -z "$1" ]]; then
    echo ""
    return
  fi
  echo "$1" | awk '
  {
    total=0;
    match($0, /([0-9]+)h/, h);
    match($0, /([0-9]+)m/, m);
    match($0, /([0-9]+)s/, s);
    if (h[1] != "") total += h[1]*3600;
    if (m[1] != "") total += m[1]*60;
    if (s[1] != "") total += s[1];
    print total;
  }'
}

parse_args() {
  local duration=""
  local bitrate="k192"
  local vbr_flag=""

  for a in "$@"; do
    if [[ $a =~ ^[0-9hms]+$ ]]; then
      duration=$a
    elif [[ $a =~ ^k[0-9]+$ ]]; then
      bitrate=$a
    elif [[ $a == "c" ]]; then
      vbr_flag="v"
    fi
  done

  echo "$duration" "$bitrate" "$vbr_flag"
}

record_audio_ffmpeg() {
  local channels=$1      # mono/stereo
  local duration=$2
  local bitrate=$3
  local vbr_flag=$4      # "v" - VBR, пусто - CBR

  read -p "Введите имя файла (без расширения), Enter - дефолт: " filename
  if [[ -z "$filename" ]]; then
    filename="stream_$(date '+%Y-%m-%d_%H-%M-%S')"
  fi
  local outfile="${record_dir}/${filename}.mp3"

  local ch_num=2
  if [[ "$channels" == "mono" ]]; then
    ch_num=1
  fi

  local timeout_sec
  timeout_sec=$(get_seconds "$duration")

  local codec_opts=""
  if [[ "$vbr_flag" == "v" ]]; then
    codec_opts="-q:a 4"   # VBR: лучше ставить 0-9, где 0 — max качество
  else
    if [[ "$bitrate" =~ ^k([0-9]+)$ ]]; then
      local br_num="${BASH_REMATCH[1]}"
      # Проверяем разумность битрейта (32–320)
      if (( br_num < 32 || br_num > 320 )); then
        echo "Предупреждение: битрейт вне диапазона 32-320, будет использован 192k."
        br_num=192
      fi
      codec_opts="-b:a ${br_num}k"
    else
      echo "Неверный формат битрейта, используем 192k."
      codec_opts="-b:a 192k"
    fi
  fi

  local source_name
  source_name=$(pactl list sources short | grep monitor | head -n1 | cut -f2)
  if [[ -z "$source_name" ]]; then
    echo "Ошибка: не найден PulseAudio источник-монитор. Проверьте состояние PulseAudio."
    return 1
  fi

  echo "Начинается запись: $channels, битрейт ${bitrate}, $( [[ -z $duration ]] && echo 'до Ctrl+C' || echo $duration ), файл: $outfile"
  echo "Остановить запись можно Ctrl+C"

  if [[ -n "$timeout_sec" && "$timeout_sec" -gt 0 ]]; then
    ffmpeg -hide_banner -loglevel info -f pulse -i "$source_name" -ac "$ch_num" $codec_opts -t "$timeout_sec" "$outfile"
  else
    ffmpeg -hide_banner -loglevel info -f pulse -i "$source_name" -ac "$ch_num" $codec_opts "$outfile"
  fi

  echo "Запись завершена: $outfile"
  xdg-open "$record_dir" >/dev/null 2>&1 &
}

rec() {
  local args=($(parse_args "$@"))
  record_audio_ffmpeg stereo "${args[0]}" "${args[1]}" "${args[2]}"
}
recm() {
  local args=($(parse_args "$@"))
  record_audio_ffmpeg mono "${args[0]}" "${args[1]}" "${args[2]}"
}
recc() {
  local args=($(parse_args "$@"))
  # Для recc принудительно CBR - убираем флаг VBR
  record_audio_ffmpeg stereo "${args[0]}" "${args[1]}" ""
}
recmc() {
  local args=($(parse_args "$@"))
  # Для recmc принудительно CBR - убираем флаг VBR
  record_audio_ffmpeg mono "${args[0]}" "${args[1]}" ""
}
reccm() {
  local args=($(parse_args "$@"))
  # Дополнительный alias, можно убрать
  record_audio_ffmpeg mono "${args[0]}" "${args[1]}" ""
}

