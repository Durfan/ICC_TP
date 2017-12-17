#!/bin/bash

IMDBDIR=$1
OUTPUTDIR=$2

LOGO="\x1b[36mZEROUM - IMDB Extração e Manuseio v0.0.3\x1b[0m"
amenu="(1) Pre-Processamento";
bmenu="(2) Verificar PP";
cmenu="(3) Extrair itens";
dmenu="(4) Extrair item 10";
emenu="(5) Ver dados extraidos"; 
fmenu="(6) Ver dados item 10";

invalida() { MSG="\x1b[31mOpcao invalida...\x1b[0m" ; }

logo() {
    echo -e "\x1b[33m   ___  __   ____________ _____  _    _ _    _ __  __ "
    echo "  / _ \/_ | |___  /  ____|  __ \| |  | | |  | |  \\/  |"
    echo " | | | || |    / /| |__  | |__) | |  | | |  | | \  / |"
    echo " | | | || |   / / |  __| |  _  /| |  | | |  | | |\\/| |"
    echo " | |_| || |  / /__| |____| | \ \\| |__| | |__| | |  | |"
    echo "  \___/ |_| /_____|______|_|  \\_\\\\____/ \\____/|_|  |_|"
    echo -e "                              IMDB Extracao e Manuseio\x1b[0m"              
}

themenu() {
    clear
    echo `date`
    echo
    logo
    echo
    echo -e $amenu
    echo -e $bmenu
    echo -e $cmenu
    echo -e $dmenu
    echo -e $emenu
    echo -e $fmenu
    echo ----------------------
    echo -e "(0) Sair"
    echo
    echo Digite a opcao e pressione ENTER ;
    echo -e $MSG
}

pre() {
    START_TIME=$SECONDS
    clear
    cd $IMDBDIR
    echo -e $LOGO
    echo
    echo ---------- PRE-PROCESSAMENTO ----------
    echo
    echo "\$Concatenado arquivos..."
    join -t $'\t' -o 2.1,2.2,2.3,2.4,2.5,2.6,2.7,2.8,2.9,1.2,1.3 title.ratings.tsv title.basics.tsv > ../$OUTPUTDIR/titles.tsv
    echo "\$Remover primeira linha do titles.tsv; gerar titles.all.tsv..."
    sed '1d' ../$OUTPUTDIR/titles.tsv > ../$OUTPUTDIR/titles.all.tsv
    cd ~-
    echo
    echo ------ FIM DO PRE-PROCESSAMENTO -------
    ELAPSED_TIME=$(($SECONDS - $START_TIME))
    echo -e "\n\x1b[36mTempo gasto na execucao: ${ELAPSED_TIME}s\x1b[0m"
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
}

verifica() {
    clear
    cd $OUTPUTDIR
    echo -e $LOGO
    echo
    echo -e "#Linhas nos arquivos originais:"
    wc -l ../$IMDBDIR/title.basics.tsv
    wc -l ../$IMDBDIR/title.ratings.tsv
    echo -e "\n#Linhas nos arquivos gerados:"
    wc -l titles.tsv
    wc -l titles.all.tsv
    cd ~-
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
}

extrai() {
    START_TIME=$SECONDS
    clear
    cd $OUTPUTDIR
    echo -e $LOGO
    echo
    # titulos=$(sed -n '$=' titles.all.tsv)
    titulos=$(wc -l < titles.all.tsv | tr -d ' ')
    echo Total de Tiulos na Base: $titulos
    echo
    echo  ----------- EXTRACAO -----------
    echo

    echo 01: \"titleType\" unicos
    echo
    # Seleciona a coluna dois e usa pipe para organizar/selecionar os unicos na saida out1.txt
    cut -f 2 titles.all.tsv | sort | uniq | tee out1 
    echo
    
    echo 02: \"primaryTitle\" e \"originalTitle\" iguais
    # Compara as colunas 2 e 3, se forem iguais aumenta o contador, cria arquivo out2.txt com o numero de title iguais
    awk -F"\t" '{if ($3 == $4) s += 1} END{print s}' titles.all.tsv | tee out2
    echo
    
    echo 03: media das avaliacoes entre 1970 e 2000
    # Compara se a coluna 6 está entre os valores (1970 a 2000), recebe em s a nota do filme, e em t a quantidade de filmes
    awk -F"\t" '{if (1969 < $6  && $6 < 2001){s += $10; t+= 1}} END{printf("%.4f\n", s/t)}' titles.all.tsv | tee out3

    # Solucao para o erro no ponto flutuante em bash no macOS
    # soma=$(awk -F"\t" '{if ($6>=1970 && $6<=2000){print $10}}' titles.all.tsv | paste -sd+ - | bc) 
    # total=$(awk -F"\t" '{if ($6>=1970 && $6<=2000){count++}} END{print count}' titles.all.tsv)
    # bc <<< "scale=10;$soma / $total"
    echo
    
    echo 04: media das avaliacoes entre 2000 e 2016
    # Compara se a coluna 6 está entre os valores (2000 a 2016), recebe em s a nota do filme, e em t a quantidade de filmes
    awk -F"\t" '{if (1999 < $6  && $6 < 2017){s += $10; t+= 1}} END{printf("%.4f\n", s/t)}' titles.all.tsv | tee out4
    echo
    
    echo 05: generos unicos
    # Separa a coluna 9 do arquivo, elimina (com grep -v) as linhas que possuem ',' e '\N', organiza (com sort)
    # por ordem alfabetica, elimina (com uniq) as entradas repetidas, conta as linhas com wc -l
    cut -f 9 titles.all.tsv | grep -v "," | grep -v "\\N" | sort | uniq | wc -l | tr -d ' ' | tee out5

    # Patch para correcao da resposta
    # cut -f 9 titles.all.tsv | tr ',' '\n' | sort | uniq | grep -v '\\N' | wc -l | tr -d ' '
    echo
    
    echo 06: titulos classificados como \"Action\"
    # Separa a coluna 9 do arquivo, separa todas linhas que possuem a palavra Action, conta as linhas
    cut -f 9 titles.all.tsv | grep "Action" | wc -l | tr -d ' ' | tee out6
    echo
    
    echo 07: titulos \"Adventure\" produzidos desde 2005
    # Procura pela coluna 9 a palavra Adventure dede que o ano nao tenha "\N"
    # e seja maior ou igual a 2005, retorna o total de l
    awk -F"\t" '$9 ~ /Adventure/ && $6 != "\\N" && $6 >= 2005 {print $6,"\t",$9,"\t",$3}' titles.all.tsv | sort | wc -l | tr -d ' ' | tee out7
    echo
    
    echo 08: titulos \"Fantasy\" e \"Sci-Fi\" produzidos desde 2010
    # Procura pela coluna 9 a palavras Adventure ou Sci-Fi dede que o ano nao tenha "\N"
    # e seja maior ou igual a 2010, retorna o total de l
    awk -F"\t" '{if (($9 ~ /Fantasy/ || $9 ~ /Sci-Fi/) && ($6 != "\\N" && $6 >= 2010)) print $6,"\t",$9,"\t",$3}' titles.all.tsv | sort | wc -l | tr -d ' ' | tee out8
    echo
    
    echo 09: razao de titulos com \"startYear=1970\" pelo total
    # Atribiu a uma var o valor de linhas encontradas que possuam o ano igual 1970;
    # divide var pelo total de titulos atraves de bc
    item9=$(awk -F"\t" '{if ($6 == 1970 && $6 != "\\N") print $6}' titles.all.tsv | wc -l | tr -d ' ')
    bc <<< "scale=5;$item9 / $titulos" | tee out9
    echo
    
    echo 11: filmes com genero unico
    # Separa a coluna 9, elimina as linhas que possuem ',' e '\N' sobrando
    # somente os generos unicos e conta as linhas com wc -l
    cut -f 9 titles.all.tsv | grep -v "," | grep -v '\\N' | wc -l | tr -d ' ' | tee out11
    echo

    echo 12: cinco generos com mais titulos
    echo
    # Separa a coluna 9, troca ',' por '\n' separando as linhas com mais de um item
	# faz a ordenação e a contagem de itens iguais, retira o item '\N' da contagem
	# ordena em ordem decrescente e obtem os 5 primeiros itens
	cut -f 9 titles.all.tsv | tr -s "," "\n" | sort | uniq -c | grep -v "\N" | sort -g -r | tr -d [:digit:] | tr -d ' ' | head -n 5 | tee out12
    
    # cut -f 9 titles.all.tsv | tr ',' '\n' | sort | grep -v '\\N' | uniq -c | sort -n -r | tr -d [:digit:] | tr -d ' ' | head -5 | tee out12
    echo
    
    echo 13: media das avaliacoes por titulos \> \"genero resultado\"
    # generos=$(cut -f 9 titles.all.tsv | tr ',' '\n' | sort | grep -v '\\N' | uniq | sort | tr -d [:digit:] | tr -d ' ')
    # for i in $generos;
    # do
    #    item13=$(awk -F"\t" -v pat="$i" '{if ($9 == pat){print $10}}' titles.all.tsv | paste -sd+ - | bc)
    #    total13=$(cut -f 9 titles.all.tsv | tr ',' '\n' | grep -v '\\N' | sort | grep -c $i)
    #    media13=$(bc <<< "scale=5;$item13/$total13")
    #    echo -e $i" "$media13 | tee -a out13
    #    item13=
    #    total13=
    #    media13=
    # done

    echo -e "14: media das avaliacoes por titulos > \"genero resultado\" && numVotes>100"
    echo -e "15: media das avaliacoes por tı́tulos > \"tipo resultado\"\n"

    echo -e 16: razao de titulos com \"runtimeMinutes\" entre 80\-120min pelo total
    # Atribiu a uma var o valor de linhas encontradas apos selecionar a coluna 8;
    # inverte a busca por "\N" e verificar de a duracao esta em 80-120
    item16a=$(cut -f 8 titles.all.tsv | grep -v "\\N" | awk '$NF >= 80 && $NF <= 120' | wc -l | tr -d ' ')
    item16b=$(cut -f 8 titles.all.tsv | grep -c -v "\\N")
    bc <<< "scale=5;$item16a / $item16b" | tee out16
    echo

    echo 17: top 10 \"Action\" melhor avaliados desde 2005
    echo
	# Localizar filmes nos devidos parametros, ordenar pela nota dos filmes e extrair os 10 primeiros	
	awk -F"\t" '{if(($9 ~ /Action/) && ($6 >= 2005 && $6 != "\N") && ($2 ~ /movie/) && ($11 > 100)) print $3,"\t",$10}' titles.all.tsv | sort -r -g -t$'\t' -k2 | head -n 10 | tr '\t' ' ' | tee out17
	echo

    echo 18: top 5 \"Comedy\" melhor avaliados
    echo
	# Localizar filmes nos devidos parametros, ordenar pela nota dos filmes e extrair os 5 primeiros	
	awk -F"\t" '{ if (($2 ~ /movie/) && ($9 ~ /Comedy/) && ($11 > 100) && ($8 > 200)) print $3,"\t",$10}' titles.all.tsv | sort -r -g -t$'\t' -k2 |  head -n 5 | tr '\t' ' ' | tee out18
    echo

    cd ~-
    echo
    echo -------- FIM DO EXTRACAO --------
    ELAPSED_TIME=$(($SECONDS - $START_TIME))
    echo -e "\n\x1b[36mTempo gasto na execucao: ${ELAPSED_TIME}s\x1b[0m"
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
}

extrai10() {
    START_TIME=$SECONDS
    clear
    cd $OUTPUTDIR
    echo -e $LOGO
    echo
    echo  ------- EXTRACAO ITEM 10 -------
    # atribui a uma var os anos de forma unica; realiza um laço que atribui uma var para os
    # totais de titulos por ano divididos pelo total de titulos de um periodo
    anos=$(cut -f 6 titles.all.tsv | sort | uniq | sed '$d')
    range=$(cut -f 6 titles.all.tsv | awk '$NF >= 1971 && $NF <= 2016' | wc -l | tr -d ' ')
    echo Titulos produzidos no itervalo 1971-2016: $range
    for i in $anos;
        do
            item10=$(cut -f 6 titles.all.tsv | grep -c "$i")
            media10=$(bc <<< "scale=5;$item10/$range")
            echo -e $i"\t"$media10 | tee -a out10
            item10=
        done
    cd ~-
    echo
    echo -------- FIM DO EXTRACAO --------
    ELAPSED_TIME=$(($SECONDS - $START_TIME))
    echo -e "\n\x1b[36mTempo gasto na execucao: ${ELAPSED_TIME}s\x1b[0m"
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
}

imprime() {
    clear
    cd $OUTPUTDIR
    echo -e $LOGO
    echo
    echo -------- Item 1
    cat out1
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
    clear
    echo -e $LOGO
    echo
    echo -n " Item 2: " ; cat out2
    echo -n " Item 3: " ; cat out3
    echo -n " Item 4: " ; cat out4
    echo -n " Item 5: " ; cat out5
    echo -n " Item 6: " ; cat out6
    echo -n " Item 7: " ; cat out7
    echo -n " Item 8: " ; cat out8
    echo -n " Item 9: " ; cat out9
    echo -n "Item 11: " ; cat out11
    echo -n "Item 16: " ; cat out16
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
    clear
    echo -e $LOGO
    echo
    echo -------- Item 12
    cat out12
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
    clear
    echo -e $LOGO
    echo
    echo -------- Item 17
    echo
    cat out17
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
    clear
    echo -e $LOGO
    echo
    echo -------- Item 18
    echo
    cat out18
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
    cd ~-
}


MSG=
while true
    do
        themenu
        read answer
        MSG=
        case $answer in
        1) pre;;
        2) verifica;;
        3) extrai;;
        4) extrai10;;
        5) imprime;;
        6) less $OUTPUTDIR/out10;;
        0) break;;
        *) invalida;;
    esac
done