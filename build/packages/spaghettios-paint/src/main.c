#include <gtk/gtk.h>
#include <gdk/gdkkeysyms.h>

#define DEFAULT_W 800
#define DEFAULT_H 600
#define BRUSH_SIZES 3

typedef struct {
    GtkWidget *da;
    cairo_surface_t *surface;
    GdkRGBA fg_color;
    double brush_size;
    gboolean drawing;
    double last_x, last_y;
    char *status_text;
} PaintApp;

static void clear_surface(PaintApp *app) {
    cairo_t *cr = cairo_create(app->surface);
    cairo_set_source_rgb(cr, 1, 1, 1);
    cairo_paint(cr);
    cairo_destroy(cr);
}

static void draw_brush(cairo_t *cr, double x, double y, double size) {
    cairo_arc(cr, x, y, size / 2.0, 0, 2 * G_PI);
    cairo_fill(cr);
}

static gboolean on_draw(GtkWidget *w, cairo_t *cr, gpointer data) {
    PaintApp *app = (PaintApp *)data;
    cairo_set_source_surface(cr, app->surface, 0, 0);
    cairo_paint(cr);
    return FALSE;
}

static void draw_line(PaintApp *app, double x1, double y1, double x2, double y2) {
    cairo_t *cr = cairo_create(app->surface);
    cairo_set_source_rgba(cr, app->fg_color.red, app->fg_color.green, app->fg_color.blue, app->fg_color.alpha);
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND);
    cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND);
    cairo_set_line_width(cr, app->brush_size);
    cairo_move_to(cr, x1, y1);
    cairo_line_to(cr, x2, y2);
    cairo_stroke(cr);
    cairo_destroy(cr);
    gtk_widget_queue_draw(app->da);
}

static gboolean on_press(GtkWidget *w, GdkEventButton *e, gpointer data) {
    PaintApp *app = (PaintApp *)data;
    if (e->button == GDK_BUTTON_PRIMARY) {
        app->drawing = TRUE;
        app->last_x = e->x;
        app->last_y = e->y;
    }
    return TRUE;
}

static gboolean on_release(GtkWidget *w, GdkEventButton *e, gpointer data) {
    PaintApp *app = (PaintApp *)data;
    if (e->button == GDK_BUTTON_PRIMARY) {
        app->drawing = FALSE;
    }
    return TRUE;
}

static gboolean on_motion(GtkWidget *w, GdkEventMotion *e, gpointer data) {
    PaintApp *app = (PaintApp *)data;
    if (app->drawing) {
        draw_line(app, app->last_x, app->last_y, e->x, e->y);
        app->last_x = e->x;
        app->last_y = e->y;
    }
    return TRUE;
}

static void on_clear(GtkButton *b, gpointer data) {
    PaintApp *app = (PaintApp *)data;
    clear_surface(app);
    gtk_widget_queue_draw(app->da);
}

static void on_save(GtkButton *b, gpointer data) {
    PaintApp *app = (PaintApp *)data;
    GtkWidget *dialog = gtk_file_chooser_dialog_new("Save Image",
        NULL, GTK_FILE_CHOOSER_ACTION_SAVE, "_Cancel", GTK_RESPONSE_CANCEL, "_Save", GTK_RESPONSE_ACCEPT, NULL);
    GtkFileChooser *chooser = GTK_FILE_CHOOSER(dialog);
    GtkFileFilter *filter = gtk_file_filter_new();
    gtk_file_filter_set_name(filter, "PNG images");
    gtk_file_filter_add_mime_type(filter, "image/png");
    gtk_file_chooser_add_filter(chooser, filter);
    gtk_file_chooser_set_current_name(chooser, "untitled.png");
    if (gtk_dialog_run(GTK_DIALOG(dialog)) == GTK_RESPONSE_ACCEPT) {
        char *path = gtk_file_chooser_get_filename(chooser);
        cairo_surface_write_to_png(app->surface, path);
        g_free(path);
    }
    gtk_widget_destroy(dialog);
}

static void set_color(GtkColorButton *btn, gpointer data) {
    PaintApp *app = (PaintApp *)data;
    gtk_color_button_get_rgba(btn, &app->fg_color);
}

static void set_brush_size(GtkComboBox *combo, gpointer data) {
    PaintApp *app = (PaintApp *)data;
    double sizes[] = {4.0, 12.0, 32.0};
    app->brush_size = sizes[gtk_combo_box_get_active(combo)];
}

static void on_about(GtkMenuItem *item, gpointer data) {
    const char *authors[] = {"SpaghettiOS Developers", NULL};
    gtk_show_about_dialog(NULL,
        "program-name", "SpaghettiPaint",
        "version", "1.0",
        "comments", "A simple paint program for SpaghettiOS",
        "authors", authors,
        "logo-icon-name", "applications-graphics",
        NULL);
}

static GtkWidget *build_menu(PaintApp *app) {
    GtkWidget *menubar = gtk_menu_bar_new();
    GtkWidget *file = gtk_menu_item_new_with_label("File");
    GtkWidget *file_menu = gtk_menu_new();
    GtkWidget *save = gtk_menu_item_new_with_label("Save");
    GtkWidget *quit = gtk_menu_item_new_with_label("Quit");
    g_signal_connect(save, "activate", G_CALLBACK(on_save), app);
    g_signal_connect(quit, "activate", G_CALLBACK(gtk_main_quit), NULL);
    gtk_menu_shell_append(GTK_MENU_SHELL(file_menu), save);
    gtk_menu_shell_append(GTK_MENU_SHELL(file_menu), quit);
    gtk_menu_item_set_submenu(GTK_MENU_ITEM(file), file_menu);

    GtkWidget *help = gtk_menu_item_new_with_label("Help");
    GtkWidget *help_menu = gtk_menu_new();
    GtkWidget *about = gtk_menu_item_new_with_label("About");
    g_signal_connect(about, "activate", G_CALLBACK(on_about), app);
    gtk_menu_shell_append(GTK_MENU_SHELL(help_menu), about);
    gtk_menu_item_set_submenu(GTK_MENU_ITEM(help), help_menu);

    gtk_menu_shell_append(GTK_MENU_SHELL(menubar), file);
    gtk_menu_shell_append(GTK_MENU_SHELL(menubar), help);
    return menubar;
}

int main(int argc, char *argv[]) {
    gtk_init(&argc, &argv);

    PaintApp app = {0};
    app.brush_size = 4.0;
    gdk_rgba_parse(&app.fg_color, "#000000");

    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), "SpaghettiPaint");
    gtk_window_set_default_size(GTK_WINDOW(window), DEFAULT_W, DEFAULT_H);
    gtk_window_set_position(GTK_WINDOW(window), GTK_WIN_POS_CENTER);
    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);

    app.surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, DEFAULT_W, DEFAULT_H);
    clear_surface(&app);

    app.da = gtk_drawing_area_new();
    gtk_widget_set_size_request(app.da, DEFAULT_W, DEFAULT_H);
    g_signal_connect(app.da, "draw", G_CALLBACK(on_draw), &app);
    g_signal_connect(app.da, "button-press-event", G_CALLBACK(on_press), &app);
    g_signal_connect(app.da, "button-release-event", G_CALLBACK(on_release), &app);
    g_signal_connect(app.da, "motion-notify-event", G_CALLBACK(on_motion), &app);
    gtk_widget_set_events(app.da, GDK_BUTTON_PRESS_MASK | GDK_BUTTON_RELEASE_MASK | GDK_POINTER_MOTION_MASK);

    GtkWidget *menubar = build_menu(&app);

    // Toolbar
    GtkWidget *toolbar = gtk_toolbar_new();
    gtk_toolbar_set_style(GTK_TOOLBAR(toolbar), GTK_TOOLBAR_BOTH);

    GtkToolItem *color_btn = gtk_tool_item_new();
    GtkWidget *color_btn_w = gtk_color_button_new_with_rgba(&app.fg_color);
    gtk_color_button_set_title(GTK_COLOR_BUTTON(color_btn_w), "Brush Color");
    g_signal_connect(color_btn_w, "color-set", G_CALLBACK(set_color), &app);
    gtk_container_add(GTK_CONTAINER(color_btn), color_btn_w);
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), color_btn, -1);

    GtkToolItem *size_label = gtk_tool_item_new();
    GtkWidget *size_combo = gtk_combo_box_text_new();
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(size_combo), "Small");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(size_combo), "Medium");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(size_combo), "Large");
    gtk_combo_box_set_active(GTK_COMBO_BOX(size_combo), 0);
    g_signal_connect(size_combo, "changed", G_CALLBACK(set_brush_size), &app);
    gtk_container_add(GTK_CONTAINER(size_label), size_combo);
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), size_label, -1);

    GtkToolItem *clear_btn = gtk_tool_button_new(NULL, "Clear");
    g_signal_connect(clear_btn, "clicked", G_CALLBACK(on_clear), &app);
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), clear_btn, -1);

    GtkToolItem *save_btn = gtk_tool_button_new(NULL, "Save");
    g_signal_connect(save_btn, "clicked", G_CALLBACK(on_save), &app);
    gtk_toolbar_insert(GTK_TOOLBAR(toolbar), save_btn, -1);

    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_box_pack_start(GTK_BOX(vbox), menubar, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(vbox), toolbar, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(vbox), app.da, TRUE, TRUE, 0);

    // Status bar
    GtkWidget *status = gtk_statusbar_new();
    gtk_statusbar_push(GTK_STATUSBAR(status), 0, "SpaghettiPaint — Draw something!");
    gtk_box_pack_start(GTK_BOX(vbox), status, FALSE, FALSE, 0);

    gtk_container_add(GTK_CONTAINER(window), vbox);
    gtk_widget_show_all(window);
    gtk_main();

    cairo_surface_destroy(app.surface);
    return 0;
}
