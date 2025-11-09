#include <amxmodx>

public plugin_init()
{
    register_plugin("Gravity Setter", "1.6", "Evgeniy");

    // Регистрируем команду с параметром
    register_clcmd("grav", "cmd_grav");

    log_amx("GravitySetter: ready, use /grav <value>");
}

public cmd_grav(id)
{
    new param[16];

    // Используем read_argv для получения первого аргумента
    if(!read_argv(1, param, charsmax(param)))
    {
        client_print(id, print_chat, "Usage: /grav <value>");
        return PLUGIN_HANDLED;
    }

    new Float:value = str_to_float(param);

    server_cmd("sv_gravity %.0f", value);
    client_print(id, print_chat, "Gravity set to %.0f", value);

    return PLUGIN_HANDLED;
}

