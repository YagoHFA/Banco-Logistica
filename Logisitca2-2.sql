create database if not exists Logistica;
use logistica;

drop table if exists Cidade;
create table if not exists Cidade(
id 				int 		primary key		 auto_increment,
nome			varchar(60) not null,
Km				int not null,
descrição 		varchar(60) not null
);

drop table if exists Motoristas;
create table if not exists Motoristas(
id 				int 		primary key		 auto_increment,
nome			varchar(60) not null,
CNH				int default null ,
dataNasc		date  not null
);

drop table if exists Veiculo;
create table if not exists Veiculo(
id 				int 		primary key		 auto_increment,
modelo			int references modelo(id), 
placa			varchar(60) not null,
cor				int references modelo(id) 
);

drop table if exists modelo;
create table if not exists modelo(
id				int			primary key 	auto_increment,
modelo			varchar(60) not null
);

drop table if exists cor;
create table if not exists cor(
id 				int 		primary key 	auto_increment,
cor				varchar(60) not null
);



drop table if exists logViagem;
create table if not exists logViagem(
id 		int primary key auto_increment,
estado	varchar(60) not null,
idViagem int references viagem(id),
usuario	varchar(60) not null,
dataMod	datetime not null
);


drop table if exists distancia;
create table if not exists distancia(
idCidade1 int references cidade(id),
idCidade2 int references cidade(id),
primary key (idCidade1, idCidade2),
distancia int
);

drop table if exists Viagem;
create table if not exists Viagem(
id			int	primary key	auto_increment,
idCidInit	int references Cidade(id),
idCidFinal	int references Cidade(id),
idMotorista int references Motorista(id),
idVeiculo	int references Veiculo(id),
dataSaidas	date not null
);


delimiter $
-- Criação da Procedure
drop procedure if exists inserirViagem$
create procedure inserirViagem(
cidInit varchar(60),
cidFin	varchar(60),
Condu	varchar(60),
veic	varchar(60)
)
begin
		
		set @CidadeInitId = (select id from Cidade where nome = cidInit);
		set @CidFinalId = (select id from Cidade where nome = cidFin);
		set @Condutor = (select id from Motoristas where nome = Condu);
		set @veiculo = (select veiculo.id from Veiculo join modelo on modelo.id = Veiculo.modelo where modelo.modelo = veic);
        
        
	insert into viagem values(null, @CidadeInitId, @CidFinalId, @Condutor, @Veiculo, curdate() + 1);

    insert into distancia values(@CidadeInitId, @CidFinalId,calcDistancia(@CidadeInitId, @CidFinalId ));
end$ 
delimiter ;

-- Criaação dos Triggers
delimiter $
create trigger CreateLogViagem after insert on viagem
	for each row
		begin 
            insert into logViagem values (null, "Criado", new.id , user(), sysdate());
        end$  
        
delimiter $
create trigger AtualizadoLogViagem after update on viagem
	for each row
		begin 
            insert into logViagem values (null, "Atualizado", new.id , user(), sysdate());
        end$  
delimiter $
create trigger DeleteLogViagem after delete on viagem
	for each row
		begin 
            insert into logViagem values (null, "Deletado", old.id , user(), sysdate());
        end$  
        
delimiter ;

delimiter $

create trigger chk_localInsert before insert on viagem
	for each row
		begin 
           if new.idCidinit = new.idCidFinal then
           signal sqlstate '45000'
           set message_text = "O local de destinonão pode ser o mesmo que de origem",
           mysql_errno = 400;
           end if;
            if calcDistancia(new.idCidinit, new.idCidFinal ) = 0 then
           signal sqlstate '45000'
           set message_text = "A viagem deve ser maior que 0 KM",
           mysql_errno = 401;
           end if;
           end $
        
   
create trigger chk_localUpdate before update on viagem
	for each row
		begin 
           if new.idCidinit = new.idCidFinal then
           signal sqlstate '45000'
           set message_text = "O local de destinonão pode ser o mesmo que de origem",
           mysql_errno = 400;
           end if;
           
           if calcDistancia(new.idCidinit, new.idCidFinal ) = 0 then
           signal sqlstate '45000'
           set message_text = "A viagem deve ser maior que 0 KM",
           mysql_errno = 401;
           end if;
        end$    
        
delimiter ;



delimiter $
-- Criação das Function
drop function if exists calcDistancia$
create function calcDistancia(distInit int, distFinal int)
	returns int deterministic
    begin
    set @distInit = (select km from cidade where id = distInit);
    set @distFinal = (select km from cidade where id = distFinal);
		if @distInit > @distFinal then
				set @total = @distInit - @distFinal;
			else 
				set @total = @distFinal - @distInit;
		end if;
		return @total;
        
        end$
delimiter ;

delimiter $
drop function if exists qtdViagens;
create function qtdViagens(placa varchar(60))
	returns int deterministic
    begin
		set @qtdViagens = (select count(idVeiculo) from viagem join veiculo on veiculo.id = viagem.IdVeiculo where veiculo.placa = placa);
        return @qtdViagens;
	end$
delimiter ;

delimiter $
drop function if exists disCidade$
create function disCidade(cidade1 varchar(60), cidade2 varchar(60))
	returns  int deterministic
    begin
    set @Dis1 = (select km from cidade where nome = cidade1);
    set @Dis2 = (select km from cidade where nome = cidade2);
    set @Disf = calcDistancia(@Dis1, @Dis2);
    return @Disf;
    end$
    
    
delimiter ;


-- inserts
insert into Cidade values (null, 'São paulo', 40, 'Capital do estado');
insert into Cidade values (null, 'Paulinia', 160, 'Cidade do estado');
insert into Cidade values (null, 'Sorocaba', 80, 'Cidade do estado');
insert into Cidade values (null, 'Votoratim', 50, 'Cidade do estado');
insert into Cidade values (null, 'Itu', 60, 'Cidade do estado');
insert into Cidade values (null, 'Indaiatuba', 20, 'Cidade do estado');

insert into cor values	(null, 'amarelo'),
						(null, 'vermelho'),
                        (null, 'preto'),
                        (null, 'branco');
                        
insert into modelo values 	(null, 'HB20'),
							(null,'Renault'),
                            (null,'Chevrolet Onix'),
                            (null,'Fiat Argo'),
                            (null, 'Volkswagen Polo');

insert into Motoristas values (null, 'Paulo', 1234567810, '2003-01-07');
insert into Motoristas values (null, 'João', 0987654321, '2000-11-22');
insert into Motoristas values (null, 'Ana', null, '1998-06-30');
insert into Motoristas values (null, 'Paula', 0547896321, '1980-09-17');
insert into Motoristas values (null, 'Luiz', null, '2004-03-31');

insert into  Veiculo values (null, 1, 'hdd-212', 1 );
insert into  Veiculo values (null, 3, 'yag-331', 3 );
insert into  Veiculo values (null, 4, 'ddf-031', 2 );
insert into  Veiculo values (null, 2, 'ket-119', 1 );
insert into  Veiculo values (null, 5, 'jhg-017', 4 );

-- utilização da procedure
 call inserirViagem ('São Paulo', 'Paulinia', 'Paulo', 'HB20');
 call inserirViagem ('São Paulo', 'Sorocaba', 'Ana', 'Renault');
 call inserirViagem ('Paulinia', 'Sorocaba', 'Ana', 'Renault');
 call inserirViagem ('Votoratim', 'Itu', 'Paulo', 'HB20');
 call inserirViagem ('São Paulo', 'Indaiatuba', 'Luiz', 'Chevrolet Onix');
 call inserirViagem ('Indaiatuba', 'Sorocaba', 'João', 'Chevrolet Onix');
 call inserirViagem ('São Paulo', 'Itu', 'Paula', 'Fiat Argo');
 call inserirViagem ('Itu', 'Sorocaba', 'Ana', 'Renault');
 call inserirViagem ('Votoratim', 'São Paulo', 'Paula', 'Fiat Argo');
 call inserirViagem ('Itu', 'Indaiatuba', 'Luiz', 'Volkswagen Polo');
 

-- Selecione a distancia entre as cidades
select a.nome, b.nome , distancia from distancia join cidade a on a.id = distancia.idCidade1
												 join cidade b on b.id = distancia.idCidade2;
-- Seleciona os Mostoristas com CNH não informada
select nome, CNH from Motoristas where CNH is null; 


-- Criação da view
create or replace view RelatorioViagens as 
	select  A.nome 'Cidade de Origem', 
    B.nome 'Cidade de Destino', 
    motoristas.nome 'Nome do Motorista',
    veiculo.placa 'Placa do veiculo', 
    modelo.modelo 'Modelo do veiculo',
    calcDistancia(A.id, B.id) 'Distancia (KM)', 
    viagem.dataSaidas 'Data de saida' from viagem 
		join cidade A on viagem.idCidInit = A.id
        join cidade B on viagem.idCidFinal = B.id
        join motoristas on motoristas.id = viagem.idMotorista
        join veiculo on veiculo.id = viagem.idVeiculo
        join modelo on veiculo.modelo = modelo.id
		order by A.nome desc;
-- utilização da view
    select * from RelatorioViagens;
    
