# Ćwiczenie 2

# Materialy
- Załączony do laboratorium program
- Napisane na potrzeby laboratorium skrypty _execute.sh_ oraz _plot.sh_

# Przeprowadzenie
Celem laboratorium była analiza błędu powstałego przy interpolacji funkcji w trakcie rozwiązywania podanego zadania metodą elementów skończonych. Załączony do laboratorium program służy do obliczania skonfigurowanych w pliku _deck.com_ zadań, tą właśnie metodą. Interfejs programu dostarcza nam szereg przydatnych funkcji:
- _mesh_: pozwalająca skonfigurować siatkę punktów na których liczone będzie rozwiązanie
- _adapth_: ekwiwalent, działający tylko na punktach z największym błędem
- _enrich,global,order=p_: pozwalająca wybrać stopień aproksymacji _p_
- _plot_: wyświetlająca siatkę
- _solve_: rozwiązująca zadanie
- _profile=1_: wyświetlająca rozwiązanie
- _twodim_: rysująca mapę dwuwymiarowego rozwiązania
- _errest_: wyświetla błąd obliczony dla ostatnio wyliczonego rozwiązania

Polecenie _errest_ wyświetla błąd w następującym formacie (dane przykładowe):

```plaintext
TOTAL NDOF = 11 log10 = 0.1041E + 01
TOTAL ERRORS :
L2 : 0.4325E − 01 log10 = −.1364E + 01
H1 : 0.1207E + 01 log10 = 0.8166E − 01
MAX : 0.4252E + 00 log10 = −.3714E + 00
```

Interesującymi danymi dla nas są dane z linii _TOTAL NDOF_ oraz _H1_. Są to kolejno, liczba stopni swobody rozwiązania oraz stopień błędu, oba podane obok w skali logarytmicznej.

Będziemy rozwiązywać następujące zadania wielokrotnie (4-5 razy, przy zadaniu C program nie działał poprawnie dla większej ilości rozwiązań):

- A ![](https://latex.codecogs.com/png.latex?u(x\)%20%3D%20\(1%20-%20x\)\(%5Carctan%20a\(x%20-%20x_0\)%20%2B%20%5Carctan%20ax_0\)%2C%20a%20%3D%2036%2C%20x_0%20%3D%200.53%2C\))
- B ![](https://latex.codecogs.com/png.latex?u(x\)%20%3D%20x^\alpha%20&plus;%20\(1%20-%20x\)^\beta%20%2C%20\alpha%20%3D%200.61%2C%20\beta%20%3D%200.75%2C%20\alpha%2C%20\beta%20\in%20[0.55%2C%200.80])
- C ![](https://latex.codecogs.com/png.latex?u(x\)%20%3D%20\arctan%20a\(r%20-%20r_0\)%2C%20\text{where}%20r%20%3D%20\sqrt{\(x%20-%20x_0\)^2%20&plus;%20\(y%20-%20y_0\)^2}]%2C%20r_0%20%3D%20\sqrt{(1%2F2%20-%20x_0\)^2%20&plus;%20(1%2F2%20-%20y_0\)^2}%2C%20a%20%3D%2045%2C%20x_0%20%3D%202.60%2C%20y_0%20%3D%202.51%2C)

Zadanie sprowadza się do wykonania ogromnej ilości operacji w programie. Aby ułatwić sobie proces, napisano specjalny skrypt automatyzujący działania:
```bash
#!/bin/bash

if [[ $# -ne 4 ]]; then
  echo "Invalid number of arguments. Please provide 4 arguments."
  exit 1
fi

i=$1
p=$2
assignment_number=$3
f=$4

if [[ ! $i =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid input for i. Please enter a positive integer."
  exit 1
fi

if [[ ! $p =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid input for p. Please enter a positive integer."
  exit 1
fi

if [[ ! $assignment_number =~ ^[1-2]$ ]]; then
  echo "Invalid input for assignment_number. Please enter either 1 or 2."
  exit 1
fi

if [[ ! $f =~ ^[1-3]$ ]]; then
  echo "Invalid input for f. Please enter either 1, 2, or 3."
  exit 1
fi

initial_input="deck
mesh
enrich,global,order=$p
plot
plot
end"

repeated_input="
solve
"

if [[ $f == 3 ]]; then
  repeated_input+="
twodim"
else
  repeated_input+="
profile=1"
fi

repeated_input+="
errest"

if [[ $assignment_number == 1 ]]; then
  repeated_input+="
mesh"
fi

if [[ $assignment_number == 2 ]]; then
  repeated_input+="
adapth"
fi

repeated_input+="
refine,global
end
"

for ((count=1; count<i; count++)); do
  initial_input="$initial_input
$repeated_input"
done

echo "$initial_input" | ../a.out_debian | tee output.txt
sed -i '/\*\*\*ERROR READING INPUT FILE/,$ d' output.txt
```

Program przyjmuje cztery argumenty: _i_, _p_, _a_ oraz _f_. Są to kolejno:
- _i_: liczba iteracji programu
- _p_: stopień aproksymacji p
- _a_: zadanie (pierwsze lub drugie)
- _f_: funkcja (1, 2 lub 3 dla zadań A, B lub C)

Warto zauważyć że skrypt nie zmienia automatycznie funkcji, na podstawie samego inputu, a jedynie dostosowuje swoje operacje do danej funkcji. Samą funkcję należy zmienić w odpowiednim pliku _deck.com_.
Skrypt buduje dane wejściowe na podstawie standardowych danych powtarzanych przy każdej iteracji, a następnie modyfikuje je w zależności od podanych argumentów i powtarza je i razy. Uruchamia on potem program dostarczony do zadania wraz ze zbudowanymi danymi wejściowymi i zapisuje dane wyjściowe do pliku _output.txt_. Program nie wyłącza się od razu, pozwalając użytkownikowi na zrobienie zrzutu okna wyświetlającego wykres rozwiązania zadania.

W pliku z danymi wyjściowymi znajdują się wypisane przez errest dane potrzebne do narysowania wykresu stopnia blędu w zależności od ilości stopni swobody. Napisano skrypt _plot.sh_, rysujący interesujący nas wykres w programie _gnuplot_:

```bash
#!/bin/bash

if [[ $# -eq 0 ]]; then
  echo "Please provide files as arguments."
  exit 1
fi

temp_dir=$(mktemp -d)

gnuplot_script=$(cat <<EOF
set datafile separator " "
set title "Zaleznosc wielkosci bledu od ilosci stopnii swobody"
set xlabel "Liczba Stopni Swobody (log10)"
set ylabel "Blad (log10)"
plot
EOF
)

i=1
for filename in "$@"; do
  if [[ ! -f "$filename" ]]; then
    echo "File '$filename' does not exist."
    exit 1
  fi

  data=$(grep -E "NDOF|H1:" "$filename" | awk -F"log10=" '{print $2}')

  formatted_data_file="$temp_dir/formatted_data_$i.txt"

  echo "$data" | awk 'NR%2==1 {x=$0} NR%2==0 {print x, $0}' > "$formatted_data_file"

  line_title=$(basename "$filename")
  gnuplot_script+="\"$formatted_data_file\" title \"$line_title\" with linespoints, "

  ((i++))
done

gnuplot_script="${gnuplot_script%,*}"

gnuplot_script_file="$temp_dir/script.gp"
echo "$gnuplot_script" > "$gnuplot_script_file"

gnuplot -persist "$gnuplot_script_file"

rm -r "$temp_dir"
```

Skrypt pobiera dane z plików wyjściowych podanych jako własne argumenty, a następnie buduje na podstawie wyłuskanych danych skrypt programu gnuplot który pomoże w narysowaniu wykresu zawierającego wszystkie dane. Po zakończeniu swojego działania, skrypt usuwa, niepotrzebne już, utworzone przez siebie pliki.

# Wyniki

