CFLAGS=-pthread -D_POSIX_C_SOURCE=200809L -g -O0
ifneq ($(OS),Windows_NT)
	CFLAGS +=  -fsanitize=address -fsanitize=undefined
endif
LFLAGS=
OUTPUT=program
LIBS=-lm

# Essas duas coisas servem pra mapear quais arquivos .c dependem de 
# quais arquivos .h. Lembre-se que se o .h muda, todo .c que inclui 
# ele precisa ser compilado novamente. Esse makefile usa features 
# do GCC pra que o próprio GCC dê essa informação (seria chato 
# listar essas relações aqui no Makefile)
# http://make.mad-scientist.net/papers/advanced-auto-dependency-generation/
DEPFLAGS=-MT $@ -MMD -MP -MF build/$*.Td

# Escaneia todos os arquivos .c na raiz do projeto
SOURCES=$(wildcard *.c)
# Transforma a lista de arquivos .c numa lista de arquivos .o em build/
# O := faz com que o lado direito seja expando AGORA, e não mais tarde
OBJS:=$(patsubst %.c,build/%.o,$(SOURCES))

# all, submission e clean sempre rodam (sem checar se suas dependencias 
# estão sujas ou não)
.PHONY: all submission clean

# Cria pastas internas, o usuário querendo ou não
$(shell mkdir -p $(DEPDIR) build >/dev/null)

# Esse é o primeiro alvo não especial. make == make all 
# e make all == make program
all: build/program

# Apaga essa regra, se existir
%.o: %.c
# Todo arquivo .o tem um .c como dependencia. Quando o .c muda, o .o precisa 
# ser recompilado. $@ expande pro arquivo .o em build/ e $< expande pro 
# arquivo .c correspondente
# O arquivo .d guarda info de dependência de headers, se ele muda, também 
# precisamos recompilar.
build/%.o : %.c build/%.d
	$(CC) -Wall -Werror -std=c11 $(CFLAGS) $(DEPFLAGS) -o $@ -c $<
	mv -f build/$*.Td build/$*.d && touch $@

# Junta todos os arquivos .o em um único magnífico binário
# Se qualquer .o em $(OBJ) mudar, program precisa ser reconstruído
# O Make não entende wildcards na lista de dependências, por isso 
# a variável OBJ foi computada anteriormente, com :=
# $^ significa *todas* as dependências ($< pega só a primeira)
build/program: $(OBJS)
	$(CC) -Wall -Werror -std=c11 $(CFLAGS) $(LFLAGS) -o $@ $^ $(LIBS)
	cp build/program $(OUTPUT)

# Prepara .tar.gz pra submissão no moodle
# Note que antes de preparar o tar.gz, é feito um clean
submission: clean
	SUBNAME=$$(basename "$$(pwd)"); \
		cd ..; \
		rm -fr "$$SUBNAME.tar.gz"; \
		tar zcf "$$SUBNAME.tar.gz" "$$SUBNAME"
	@echo Trabalho empacotado em $$(cd .. && pwd)/$$(basename "$$(pwd)").tar.gz

# Limpa binários
clean:
	rm -fr build $(OUTPUT)

# Só faltam alguns  truques pra dependências automáticas de headers

# Todo arquivo de dependência é também um target. (evita erro no primeiro build)
build/%.d: ;
# Pede pro make não tratar como arquivo intermediário
.PRECIOUS: build/%.d 

# Transforma a lista de arquivos .c em uma lista de arquivos .d em build/
# Inclui esses arquivos .d (que contêm dependências de headers) como se 
# fossem parte desse makefile
include $(wildcard $(patsubst %,build/%.d,$(basename $(SOURCES))))
