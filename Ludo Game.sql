\\\create table ludogameplay (
    game_id int primary key identity(1,1),
    player_id int check (player_id in (1, 2)),
    dice_roll int check (dice_roll between 1 and 6),
    position int not null
);

--new position
create function dbo.calculatenewposition (
    @current_position int,
    @dice_roll int
)
returns int
as
begin
    declare @new_position int = @current_position + @dice_roll;
    if @new_position > 100
        set @new_position = 100;
    return @new_position;
end;
--auto update position
create trigger trg_updateposition
on ludogameplay
after insert
as
begin
    update l
    set position = dbo.calculatenewposition(
        isnull((
            select top 1 position 
            from ludogameplay 
            where player_id = i.player_id and game_id < i.game_id
            order by game_id desc
        ), 0),
        i.dice_roll
    )
    from ludogameplay l
    join inserted i on l.game_id = i.game_id;
end;
-- simulate turn
create procedure simulate_turn
as
begin
    declare @last_turn int = (select isnull(max(game_id), 0) from ludogameplay);
    declare @next_player int = case 
        when @last_turn = 0 then 1
        else case 
            when (select player_id from ludogameplay where game_id = @last_turn) = 1 then 2
            else 1
        end
    end;

    declare @dice_roll int = floor(rand() * 6) + 1;

    insert into ludogameplay (player_id, dice_roll, position)
    values (@next_player, @dice_roll, 0); 
end;
--game loops
declare @game_ongoing int = 1;

while @game_ongoing = 1
begin
    exec simulate_turn;

    select * from ludogameplay order by game_id desc;

    if exists (select 1 from ludogameplay where player_id = 1 and position = 100)
    begin
        print 'Player 1 has won!';
        set @game_ongoing = 0;
    end

    if exists (select 1 from ludogameplay where player_id = 2 and position = 100)
    begin
        print 'Player 2 has won!';
        set @game_ongoing = 0;
    end
end;
--for continuous running

delete from ludogameplay






