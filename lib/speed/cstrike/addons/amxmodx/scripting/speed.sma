#include <amxmodx>
#include <fun>

public plugin_init()
{
    register_plugin("Speed Setter", "1.0", "Evgeniy");

    register_clcmd("speed", "cmd_speed");

    log_amx("SpeedSetter: ready, use /speed <value>");
}

public cmd_speed(id)
{
    new param[16];

    // Проверяем аргумент
    if(!read_argv(1, param, charsmax(param)))
    {
        client_print(id, print_chat, "Usage: /speed <value>");
        return PLUGIN_HANDLED;
    }

    new Float:value = str_to_float(param);

    new players[32], pnum;
    get_players(players, pnum);

    for(new i = 0; i < pnum; i++)
    {
        new pid = players[i];

        // Устанавливаем скорость каждому
        set_user_maxspeed(pid, value);
    }

    client_print(0, print_chat, "Speed set to %.1f for all players!", value);

    return PLUGIN_HANDLED;
}

