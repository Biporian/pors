struct Config {
    int id;
    int active;
};

int calculate_score(struct Config *cfg, int multiplier) {
    int i;
    int total = 0;
    static const int base_offset = 50;

    /* Tests pointer comparison and selection statements */
    if (cfg == 0) {
        return -1;
    }

    /* Tests iteration, nested blocks, and complex expressions */
    for (i = 0; i < 10; i++) {
        if (cfg->active != 0) {
            total = total + (cfg->id * i) + base_offset;
        } else {
            total = total - 1;
        }
    }

    /* Tests return nodes and expressions */
    return total * multiplier;
}