#!/bin/sh

set -u

COUNT="${COUNT:-4}"
MAX_JOBS="${MAX_JOBS:-8}"
OUTPUT_ARG="${1:-}"
TMP_FILE="$(mktemp)"
RESULT_DIR="$(mktemp -d)"
ROWS_DIR="$RESULT_DIR/rows"
SEMAPHORE_PIPE="$RESULT_DIR/.semaphore"
SORTED_CSV="$RESULT_DIR/results.csv"

case "$COUNT" in
  ''|*[!0-9]*|0)
    printf '%s\n' 'COUNT must be a positive integer.' >&2
    exit 1
    ;;
esac

case "$MAX_JOBS" in
  ''|*[!0-9]*|0)
    printf '%s\n' 'MAX_JOBS must be a positive integer.' >&2
    exit 1
    ;;
esac

mkfifo "$SEMAPHORE_PIPE" || exit 1
mkdir -p "$ROWS_DIR" || exit 1
exec 3<>"$SEMAPHORE_PIPE"
rm -f "$SEMAPHORE_PIPE"

cleanup() {
  exec 3>&- 3<&- 2>/dev/null || true
  rm -f "$TMP_FILE"
  rm -rf "$RESULT_DIR"
}

trap cleanup EXIT INT TERM

cat > "$TMP_FILE" <<'EOF'
亚太地区,日本东部,东京,objectstorage.ap-tokyo-1.oraclecloud.com
亚太地区,日本中部,大阪,objectstorage.ap-osaka-1.oraclecloud.com
亚太地区,韩国中部,首尔,objectstorage.ap-seoul-1.oraclecloud.com
亚太地区,韩国北部,春川,objectstorage.ap-chuncheon-1.oraclecloud.com
亚太地区,新加坡,新加坡,objectstorage.ap-singapore-1.oraclecloud.com
亚太地区,新加坡西部,新加坡,objectstorage.ap-singapore-2.oraclecloud.com
亚太地区,澳大利亚东部,悉尼,objectstorage.ap-sydney-1.oraclecloud.com
亚太地区,澳大利亚东南部,墨尔本,objectstorage.ap-melbourne-1.oraclecloud.com
亚太地区,印度西部,孟买,objectstorage.ap-mumbai-1.oraclecloud.com
亚太地区,印度南部,海得拉巴,objectstorage.ap-hyderabad-1.oraclecloud.com
亚太地区,印度尼西亚北部,巴淡岛,objectstorage.ap-batam-1.oraclecloud.com
亚太地区,马来西亚,古来,objectstorage.ap-kulai-2.oraclecloud.com
亚太地区,以色列中部,耶路撒冷,objectstorage.il-jerusalem-1.oraclecloud.com
北美地区,美国东部,阿什本,objectstorage.us-ashburn-1.oraclecloud.com
北美地区,美国中西部,芝加哥,objectstorage.us-chicago-1.oraclecloud.com
北美地区,美国西部,凤凰城,objectstorage.us-phoenix-1.oraclecloud.com
北美地区,美国西部,圣何塞,objectstorage.us-sanjose-1.oraclecloud.com
北美地区,加拿大东南部,蒙特利尔,objectstorage.ca-montreal-1.oraclecloud.com
北美地区,加拿大东南部,多伦多,objectstorage.ca-toronto-1.oraclecloud.com
北美地区,墨西哥中部,克雷塔罗,objectstorage.mx-queretaro-1.oraclecloud.com
北美地区,墨西哥东北部,蒙特雷,objectstorage.mx-monterrey-1.oraclecloud.com
欧洲地区,英国南部,伦敦,objectstorage.uk-london-1.oraclecloud.com
欧洲地区,英国西部,纽波特,objectstorage.uk-cardiff-1.oraclecloud.com
欧洲地区,德国中部,法兰克福,objectstorage.eu-frankfurt-1.oraclecloud.com
欧洲地区,瑞士北部,苏黎世,objectstorage.eu-zurich-1.oraclecloud.com
欧洲地区,瑞典中部,斯德哥尔摩,objectstorage.eu-stockholm-1.oraclecloud.com
欧洲地区,荷兰西北部,阿姆斯特丹,objectstorage.eu-amsterdam-1.oraclecloud.com
欧洲地区,法国中部,巴黎,objectstorage.eu-paris-1.oraclecloud.com
欧洲地区,法国南部,马赛,objectstorage.eu-marseille-1.oraclecloud.com
欧洲地区,西班牙中部,马德里,objectstorage.eu-madrid-1.oraclecloud.com
欧洲地区,西班牙中部,马德里 3,objectstorage.eu-madrid-3.oraclecloud.com
欧洲地区,意大利西北部,米兰,objectstorage.eu-milan-1.oraclecloud.com
欧洲地区,意大利北部,都灵,objectstorage.eu-turin-1.oraclecloud.com
中东地区,阿联酋东部,迪拜,objectstorage.me-dubai-1.oraclecloud.com
中东地区,阿联酋中部,阿布扎比,objectstorage.me-abudhabi-1.oraclecloud.com
中东地区,沙特阿拉伯西部,吉达,objectstorage.me-jeddah-1.oraclecloud.com
中东地区,沙特阿拉伯中部,利雅得,objectstorage.me-riyadh-1.oraclecloud.com
南美地区,巴西东部,圣保罗,objectstorage.sa-saopaulo-1.oraclecloud.com
南美地区,巴西南部,文郝多,objectstorage.sa-vinhedo-1.oraclecloud.com
南美地区,智利中部,圣地亚哥,objectstorage.sa-santiago-1.oraclecloud.com
南美地区,智利西部,瓦尔帕莱索,objectstorage.sa-valparaiso-1.oraclecloud.com
南美地区,哥伦比亚中部,波哥大,objectstorage.sa-bogota-1.oraclecloud.com
非洲地区,南非中部,约翰内斯堡,objectstorage.af-johannesburg-1.oraclecloud.com
非洲地区,摩洛哥西部,卡萨布兰卡,objectstorage.af-casablanca-1.oraclecloud.com
EOF

extract_avg_latency() {
  awk '
    /round-trip min\/avg\/max\/stddev = / {
      split($0, parts, "= ")
      split(parts[2], values_and_unit, " ")
      split(values_and_unit[1], values, "/")
      print values[2]
      found=1
      exit
    }
    /rtt min\/avg\/max\/mdev = / {
      split($0, parts, "= ")
      split(parts[2], values_and_unit, " ")
      split(values_and_unit[1], values, "/")
      print values[2]
      found=1
      exit
    }
    END {
      if (!found) {
        exit 1
      }
    }
  '
}

build_output_path() {
  input_path="$1"
  timestamp="$(date '+%Y%m%d_%H%M%S')"
  dir_name="$(dirname "$input_path")"
  file_name="$(basename "$input_path")"

  case "$file_name" in
    *.csv)
      base_name="${file_name%.csv}"
      printf '%s/%s_%s.csv\n' "$dir_name" "$base_name" "$timestamp"
      ;;
    *)
      printf '%s/%s_%s.csv\n' "$dir_name" "$file_name" "$timestamp"
      ;;
  esac
}

print_formatted_output() {
  if command -v perl >/dev/null 2>&1; then
    perl -CS - "$SORTED_CSV" <<'PL'
use strict;
use warnings;

sub display_width {
  my ($text) = @_;
  my $width = 0;
  for my $char (split //u, $text) {
    $width += ord($char) <= 0x7F ? 1 : 2;
  }
  return $width;
}

sub pad {
  my ($text, $width, $align) = @_;
  my $padding = $width - display_width($text);
  $padding = 0 if $padding < 0;
  return $align eq 'right' ? (' ' x $padding) . $text : $text . (' ' x $padding);
}

open my $fh, '<:encoding(UTF-8)', $ARGV[0] or die "Failed to open $ARGV[0]: $!";

my @rows;
while (my $line = <$fh>) {
  chomp $line;
  my @fields = split /,/, $line, -1;
  for my $field (@fields) {
    $field =~ s/^"//;
    $field =~ s/"$//;
  }
  push @rows, \@fields;
}

my @widths = map { display_width($_) } @{ $rows[0] };
for my $row (@rows[1 .. $#rows]) {
  for my $index (0 .. $#$row) {
    my $width = display_width($row->[$index]);
    $widths[$index] = $width if $width > $widths[$index];
  }
}

for my $row (@rows) {
  my @cells;
  for my $index (0 .. $#$row) {
    my $align = $index == 4 ? 'right' : 'left';
    push @cells, pad($row->[$index], $widths[$index], $align);
  }
  print join('  ', @cells), "\n";
}
PL
  else
    awk -F',' '
      NR == 1 {
        print "region\tsubregion\tcity\thostname\tavg_latency_ms\tstatus"
        next
      }
      {
        for (i = 1; i <= NF; i++) {
          gsub(/^"/, "", $i)
          gsub(/"$/, "", $i)
        }
        printf "%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $5, $6
      }
    ' "$SORTED_CSV"
  fi
}

job_index=1
while [ "$job_index" -le "$MAX_JOBS" ]; do
  printf '%s\n' '.' >&3
  job_index=$((job_index + 1))
done

row_index=0
while IFS=, read -r region subregion city hostname; do
  row_index=$((row_index + 1))
  result_file="$ROWS_DIR/$row_index.csv"

  {
    read -r _token <&3

    printf '%s\n' "Pinging $hostname ..."
    ping_output="$(ping -c "$COUNT" "$hostname" 2>&1)"
    ping_exit=$?

    avg_latency="$(printf '%s\n' "$ping_output" | extract_avg_latency 2>/dev/null || true)"

    if [ "$ping_exit" -eq 0 ] && [ -n "$avg_latency" ]; then
      sort_key="$avg_latency"
      status="ok"
    else
      sort_key="999999"
      avg_latency="N/A"
      status="failed"
    fi

    printf '%s,"%s","%s","%s","%s","%s","%s"\n' \
      "$sort_key" "$region" "$subregion" "$city" "$hostname" "$avg_latency" "$status" > "$result_file"

    printf '%s\n' '.' >&3
  } &
done < "$TMP_FILE"

wait

{
  printf '%s\n' 'region,subregion,city,hostname,avg_latency_ms,status'
  cat "$ROWS_DIR"/*.csv | sort -t, -k1,1n | cut -d, -f2-
} > "$SORTED_CSV"

if [ -n "$OUTPUT_ARG" ]; then
  OUTPUT_PATH="$(build_output_path "$OUTPUT_ARG")"
  cp "$SORTED_CSV" "$OUTPUT_PATH"
  printf '%s\n' "CSV written to $OUTPUT_PATH"
else
  print_formatted_output
fi
