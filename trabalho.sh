#!/bin/bash

IMDBDIR=$1
OUTPUTDIR=$2

LOGO="\x1b[36mZEROUM - IMDB Extração e Manuseio v0.0.4\x1b[0m"
amenu="(1) Pre-Processamento";
bmenu="(2) Verificar PP";
cmenu="(3) Extrair itens";
dmenu="(4) Ver itens extraidos"; 

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
    echo $(date)
    echo
    logo
    echo
    echo -e $amenu
    echo -e $bmenu
    echo -e $cmenu
    echo -e $dmenu
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
    ELAPSED_TIME=$((SECONDS - START_TIME))
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
    # awk -F"\t" '{if (1969 < $6  && $6 < 2001){s += $10; t+= 1}} END{printf("%.4f\n", s/t)}' titles.all.tsv | tee out3

    # Solucao para o erro no ponto flutuante em bash no macOS
    numerador=$(awk -F"\t" '{if (($6>=1970 && $6<=2000) && $6 !="\\N"){print $10}}' titles.all.tsv | paste -sd+ - | bc) 
    denominador=$(cut -f 6 titles.all.tsv | awk '$NF >= 1970 && $NF <= 2000' | wc -l | tr -d ' ')
    bc <<< "scale=4;$numerador / $denominador" | tee out3
    echo
    
    echo 04: media das avaliacoes entre 2000 e 2016
    # Compara se a coluna 6 está entre os valores (2000 a 2016), recebe em s a nota do filme, e em t a quantidade de filmes
    # awk -F"\t" '{if (1999 < $6  && $6 < 2017){s += $10; t+= 1}} END{printf("%.4f\n", s/t)}' titles.all.tsv | tee out4

    # Solucao para o erro no ponto flutuante em bash no macOS
    numerador=$(awk -F"\t" '{if ($6>=1999 && $6<=2017){print $10}}' titles.all.tsv | paste -sd+ - | bc) 
    denominador=$(cut -f 6 titles.all.tsv | awk '$NF >= 2000 && $NF <= 2016' | wc -l | tr -d ' ')
    bc <<< "scale=4;$numerador / $denominador" | tee out4
    echo
    
    echo 05: generos unicos
    # Separa a coluna 9 do arquivo, elimina (com grep -v) as linhas que possuem ',' e '\N', organiza (com sort)
    # por ordem alfabetica, elimina (com uniq) as entradas repetidas, conta as linhas com wc -l
    # cut -f 9 titles.all.tsv | grep -v "," | grep -v "\\N" | sort | uniq | wc -l | tr -d ' ' | tee out5

    # Patch para correcao da resposta
    cut -f 9 titles.all.tsv | tr ',' '\n' | sort | uniq | grep -c -v '\\N' | tee out5
    echo
    
    echo 06: titulos classificados como \"Action\"
    # Separa a coluna 9 do arquivo, separa todas linhas que possuem a palavra Action, conta as linhas
    cut -f 9 titles.all.tsv | grep -c "Action" | tee out6
    echo
    
    echo 07: titulos \"Adventure\" produzidos desde 2005
    # Procura pela coluna 9 a palavra Adventure dede que o ano nao tenha "\N"
    # e seja maior ou igual a 2005, retorna o total de l
    awk -F"\t" '$9 ~ /Adventure/ && ($6 != "\\N" && $6 >= 2005)' titles.all.tsv | sort | wc -l | tr -d ' ' | tee out7
    echo
    
    echo 08: titulos \"Fantasy\" e \"Sci-Fi\" produzidos desde 2010
    # Procura pela coluna 9 a palavras Adventure ou Sci-Fi dede que o ano nao tenha "\N"
    # e seja maior ou igual a 2010, retorna o total de l
    awk -F"\t" '($9 ~ /Fantasy/ || $9 ~ /Sci-Fi/) && ($6 != "\\N" && $6 >= 2010)' titles.all.tsv | sort | wc -l | tr -d ' ' | tee out8
    echo
    
    echo 09: razao de titulos produzidos em 1970 pelo total
    # Atribiu a uma var o valor de linhas encontradas que possuam o ano igual 1970;
    # divide var pelo total de titulos atraves de bc
    numerador=$(cut -f 6 titles.all.tsv | grep -c "1970")
    bc <<< "scale=5;$numerador / $titulos" | tee out9
    echo

    echo 10: razao de titulos produzidos entre 1971-2016 pelo total
    echo
    rm -f out10
    anos=$(cut -f 6 titles.all.tsv | awk '$NF >= 1971 && $NF <= 2016' | sort | uniq)
    for i in $anos;
        do
            numerador=$(cut -f 6 titles.all.tsv | grep -c "$i");
            media=$(bc <<< "scale=5;$numerador / $titulos");
            echo -e $i"\t"$media | tee -a out10;
        done
    echo
    
    echo 11: filmes com genero unico
    # Separa a coluna 9, elimina as linhas que possuem ',' e '\N' sobrando
    # somente os generos unicos e conta as linhas com wc -l
    cut -f 9 titles.all.tsv | grep -v "," | grep -c -v '\\N' | tee out11
    echo

    echo 12: cinco generos com mais titulos
    echo
    # Separa a coluna 9, troca ',' por '\n' separando as linhas com mais de um item
    # faz a ordenação e a contagem de itens iguais, retira o item '\N' da contagem
    # ordena em ordem decrescente e obtem os 5 primeiros itens
    cut -f 9 titles.all.tsv | tr -s "," "\n" | grep -v "\N" | sort | uniq -c | sort -n -r | tr -d [:digit:]' ' | head -n 5 | tee out12
    
    # cut -f 9 titles.all.tsv | tr ',' '\n' | sort | grep -v '\\N' | uniq -c | sort -n -r | tr -d [:digit:] | tr -d ' ' | head -5 | tee out12
    echo
    
    echo 13: media das avaliacoes \(total.aval.genero\/titulos genero\)
    echo
    rm -f out13
    generos=$(cut -f 9 titles.all.tsv | tr ',' '\n' | sort | grep -v '\\N' | uniq | sort | tr -d [:digit:] | tr -d ' ')
    for i in $generos;
        do
            numerador=$(awk -F"\t" '{if ($9 ~ /'$i'/){print $10}}' titles.all.tsv | paste -sd+ - | bc);
            denominador=$(cut -f 9 titles.all.tsv | tr ',' '\n' | grep -v '\\N' | sort | grep -c $i);
            media=$(bc <<< "scale=5;$numerador / $denominador");
            echo -e $i" "$media | tee -a out13;
        done
    echo

    echo 14: media das avaliacoes \(total.aval.genero\/titulos genero\)
    echo
    rm -f out14
    for i in $generos;
        do
            numerador=$(awk -F"\t" '{if ($9 ~ /'$i'/ && $11 > 100){print $10}}' titles.all.tsv | paste -sd+ - | bc);
            denominador=$(awk -F"\t" '{if ($9 ~ /'$i'/ && $11 > 100){print $9}}' titles.all.tsv | tr ',' '\n' | grep -v '\\N' | grep -c $i);
            media=$(bc <<< "scale=5;$numerador / $denominador");
            echo -e $i" "$media | tee -a out14;
        done
    echo

    echo 15: media das avaliacoes titleType \(total.aval.titletype\/titulos titletye\)
    echo
    rm -f temp15
    rm -f out15
    titletype=$(cut -f 2 titles.all.tsv | sort | uniq)
    for i in $titletype;
        do
            numerador=$(awk -F"\t" '{if ($2 == "'$i'"){print $10}}' titles.all.tsv | paste -sd+ - | bc);
            denominador=$(cut -f 2 titles.all.tsv | grep -c $i);
            media=$(bc <<< "scale=5;$numerador / $denominador");
            echo -e $i" "$media | tee -a temp15;
        done
    echo
    cat temp15 | sort -n -r -k2,2
    echo
    sort -t' ' -k2,2nr temp15 | tee out15
    rm -f temp15
    echo

    echo -e 16: razao de titulos com \"runtimeMinutes\" entre 80\-120min pelo total
    # Atribiu a uma var o valor de linhas encontradas apos selecionar a coluna 8;
    # inverte a busca por "\N" e verificar de a duracao esta em 80-120
    numerador=$(cut -f 8 titles.all.tsv | grep -v "\\N" | awk '$NF >= 80 && $NF <= 120' | wc -l | tr -d ' ');
    denominador=$(cut -f 8 titles.all.tsv | grep -c -v "\\N");
    bc <<< "scale=5;$numerador / $denominador" | tee out16;
    echo

    echo 17: top 10 \"Action\" melhor avaliados desde 2005
    echo
    # Localizar filmes nos devidos parametros, ordenar pela nota dos filmes e extrair os 10 primeiros	
    awk -F"\t" '{if (($9 ~ /Action/) && ($6 >= 2005 && $6 != "\N") && ($2 ~ /movie/) && ($11 > 100)) print $3,"\t",$10}' titles.all.tsv | sort -r -n -t$'\t' -k2,2 | head -n 10 | tr -d '\t' | tee out17
    echo

    echo 18: top 5 \"Comedy\" melhor avaliados
    echo
    # Localizar filmes nos devidos parametros, ordenar pela nota dos filmes e extrair os 5 primeiros	
    awk -F"\t" '{if (($2 == "movie" && $9 ~ /Comedy/) && ($11 > 100 && $8 > 200 && $8 != "\\N")) print $3,"\t",$10}' titles.all.tsv | sort -t$'\t' -k2,2nr |  head -n 5 | tr -d '\t' | tee out18
    echo

    cd ~-
    echo
    echo -------- FIM DO EXTRACAO --------
    ELAPSED_TIME=$((SECONDS - START_TIME))
    echo -e "\n\x1b[36mTempo gasto na execucao: ${ELAPSED_TIME}s\x1b[0m"
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
}

imprime() {
    clear
    cd $OUTPUTDIR
    echo -e $LOGO
    echo
    echo Item 1\:
    echo
    cat out1
    echo
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
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

    clear
    echo -e $LOGO
    echo
    echo Item 10\:
    echo
    head -5 out10
    echo -e " ...\t ..."
    tail -5 out10
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

    clear
    echo -e $LOGO
    echo
    echo -n "Item 11: " ; cat out11
    echo
    echo Item 12\:
    echo
    cat out12
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

    clear
    echo -e $LOGO
    echo
    echo Item 13\:
    echo
    head -15 out13
    echo -e " ..."
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

    clear
    echo -e $LOGO
    echo
    echo Item 14\:
    echo
    head -15 out14
    echo -e " ..."
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

    clear
    echo -e $LOGO
    echo
    echo Item 15\:
    echo
    cat out15
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

    clear
    echo -e $LOGO
    echo
    echo -n "Item 16: " ; cat out16
    echo
    echo Item 17\:
    echo
    cat out17
    echo
    read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."

    clear
    echo -e $LOGO
    echo
    echo Item 18\:
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
        4) imprime;;
        0) break;;
        *) invalida;;
        esac
    done
