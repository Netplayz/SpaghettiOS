#include <gtk/gtk.h>

static void on_quote_clicked(GtkButton *b, gpointer data) {
    const char *quotes[] = {
        "TempleOS is God's holy temple.",
        "I am a prophet of God.",
        "The CIA is after me.",
        "I'm the smartest programmer that ever lived.",
        "Natural laws are suffocating!",
        "I talk to God. He talks back.",
        "I've created a operating system for God.",
        NULL
    };
    static int idx = 0;
    GtkLabel *label = GTK_LABEL(data);
    if (quotes[idx] == NULL) idx = 0;
    gtk_label_set_text(label, quotes[idx]);
    idx++;
}

static void on_learn_more(GtkButton *b, gpointer data) {
    GtkWidget *dialog = gtk_message_dialog_new(
        GTK_WINDOW(data),
        GTK_DIALOG_MODAL,
        GTK_MESSAGE_INFO,
        GTK_BUTTONS_CLOSE,
        "Terry Davis (1969–2018)\n\n"
        "Creator of TempleOS, a highly original x86-64 operating system "
        "that he built entirely from scratch over 12 years. "
        "He wrote the compiler, kernel, graphics stack, and filesystem "
        "himself. Terry was a brilliant programmer who struggled with "
        "schizophrenia. TempleOS is his masterpiece."
    );
    gtk_dialog_run(GTK_DIALOG(dialog));
    gtk_widget_destroy(dialog);
}

int main(int argc, char *argv[]) {
    gtk_init(&argc, &argv);

    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), "Terry Davis");
    gtk_window_set_default_size(GTK_WINDOW(window), 500, 600);
    gtk_window_set_position(GTK_WINDOW(window), GTK_WIN_POS_CENTER);
    g_signal_connect(window, "destroy", G_CALLBACK(gtk_main_quit), NULL);

    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 8);
    gtk_container_set_border_width(GTK_CONTAINER(vbox), 20);

    GtkWidget *photo = gtk_image_new();
    GdkPixbuf *pixbuf = gdk_pixbuf_new_from_file_at_scale(
        "/usr/share/spaghettios-terry/terry.jpg", 400, 400, TRUE, NULL);
    if (pixbuf) {
        gtk_image_set_from_pixbuf(GTK_IMAGE(photo), pixbuf);
        g_object_unref(pixbuf);
    } else {
        // Fallback: draw a placeholder
        GdkPixbuf *fallback = gdk_pixbuf_new(GDK_COLORSPACE_RGB, TRUE, 8, 400, 400);
        guint8 *px = gdk_pixbuf_get_pixels(fallback);
        for (int y = 0; y < 400; y++) {
            for (int x = 0; x < 400; x++) {
                int i = y * gdk_pixbuf_get_rowstride(fallback) + x * 4;
                double dx = (x - 200) / 200.0, dy = (y - 200) / 200.0;
                double d = sqrt(dx*dx + dy*dy);
                if (d < 0.9) {
                    px[i+0] = 220; px[i+1] = 180; px[i+2] = 140; // skin
                } else {
                    px[i+0] = 100; px[i+1] = 100; px[i+2] = 120; // bg
                }
                px[i+3] = 255;
            }
        }
        gtk_image_set_from_pixbuf(GTK_IMAGE(photo), fallback);
        g_object_unref(fallback);
    }
    gtk_widget_set_size_request(photo, 400, 400);

    GtkWidget *name_label = gtk_label_new(NULL);
    gtk_label_set_markup(GTK_LABEL(name_label),
        "<span size='xx-large' weight='bold'>Terry Davis</span>\n"
        "<span size='small' style='italic'>1969 — 2018</span>");
    gtk_label_set_justify(GTK_LABEL(name_label), GTK_JUSTIFY_CENTER);

    GtkWidget *desc_label = gtk_label_new(
        "Creator of TempleOS — a 64-bit operating system\n"
        "written entirely from scratch by one man.");
    gtk_label_set_justify(GTK_LABEL(desc_label), GTK_JUSTIFY_CENTER);
    gtk_label_set_line_wrap(GTK_LABEL(desc_label), TRUE);

    GtkWidget *quote_label = gtk_label_new(NULL);
    gtk_label_set_markup(GTK_LABEL(quote_label),
        "<span size='large' style='italic'>\"TempleOS is God's holy temple.\"</span>");
    gtk_label_set_line_wrap(GTK_LABEL(quote_label), TRUE);
    gtk_label_set_justify(GTK_LABEL(quote_label), GTK_JUSTIFY_CENTER);

    GtkWidget *quote_btn = gtk_button_new_with_label("Another Quote");
    g_signal_connect(quote_btn, "clicked", G_CALLBACK(on_quote_clicked), quote_label);

    GtkWidget *learn_btn = gtk_button_new_with_label("Learn More");
    g_signal_connect(learn_btn, "clicked", G_CALLBACK(on_learn_more), window);

    GtkWidget *btn_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    gtk_widget_set_halign(btn_box, GTK_ALIGN_CENTER);
    gtk_box_pack_start(GTK_BOX(btn_box), quote_btn, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(btn_box), learn_btn, FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(vbox), photo, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(vbox), name_label, FALSE, FALSE, 5);
    gtk_box_pack_start(GTK_BOX(vbox), desc_label, FALSE, FALSE, 5);
    gtk_box_pack_start(GTK_BOX(vbox), quote_label, FALSE, FALSE, 10);
    gtk_box_pack_start(GTK_BOX(vbox), btn_box, FALSE, FALSE, 5);

    gtk_container_add(GTK_CONTAINER(window), vbox);
    gtk_widget_show_all(window);
    gtk_main();
    return 0;
}
