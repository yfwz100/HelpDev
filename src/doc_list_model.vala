/* doc_list_model.vala
 *
 * Copyright 2024 Zhi
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Helpdev {

  /**
   * Get the URI by relative path.
   */
  string get_relative_uri (string base_link, string relative_path) {
    var tokens = relative_path.split ("#", 2);
    var anchor = "";
    if (tokens.length > 1) {
      relative_path = tokens[0];
      anchor = "#" + tokens[1];
    }
    return File.new_for_uri (base_link).get_parent ().resolve_relative_path (relative_path).get_uri () + anchor;
  }

  public string get_doc_dir () {
    var doc_dir = Environment.get_variable ("DOCDIR");
    if (doc_dir != null && doc_dir != "") {
      return doc_dir;
    }
    return "/usr/share/doc";
  }

  public class LinkItem : Object {
    /**
     * The name of the item.
     */
    public string name { get; set; }

    /**
     * The actual URI of the link.
     */
    public string link { get; set; }

    /**
     * The list of sub `LinkItem`s.
     */
    public ListModel? sub_items { get; set; }

    /**
     * Build `LinkItem` from `Xml.Node` recursively.
     */
    public static LinkItem build_from_xml (Xml.Node* node, string base_link) {
      var item = new LinkItem ();
      item.name = node->get_prop ("name");
      item.link = get_relative_uri (base_link, node->get_prop ("link"));
      var list_model = new ListStore (typeof (LinkItem));
      for (var itr = node->children; itr != null; itr = itr->next) {
        if (itr->type != Xml.ElementType.ELEMENT_NODE || itr->name != "sub") {
          continue;
        }
        list_model.append (build_from_xml (itr, item.link));
      }
      item.sub_items = list_model;
      return item;
    }
  }

  /**
   * The symbol item.
   */
  public class SymbolItem : LinkItem {
    /**
     * The symbol type.
     */
    public string symbol_type { get; set; }
  }

  /**
   * The document item.
   */
  public class DocFileItem : LinkItem {
    /**
     * The list of `SymbolItem`s.
     */
    public ListModel symbols { get; set; }

    /**
     * Contruct `DocFileItem` from devhelp file.
     */
    public static DocFileItem read_from_devhelp_file (File help_file) {
      var dir_file = help_file.get_parent ();
      var tree = Xml.Parser.parse_file (help_file.get_path ());
      var root = tree->get_root_element ();
      var title = root->get_prop ("title");
      var link = root->get_prop ("link");
      var link_uri = dir_file.resolve_relative_path (link).get_uri ();
      var item = new DocFileItem ();
      item.name = title;
      item.link = link_uri;
      var sub_items = new ListStore (typeof (LinkItem));
      var symbols = new ListStore (typeof (SymbolItem));
      for (var itr = root->children; itr != null; itr = itr->next) {
        if (itr->name == "chapters") {
          for (var citr = itr->children; citr != null; citr = citr->next) {
            sub_items.append (LinkItem.build_from_xml (citr, link_uri));
          }
        } else if (itr->name == "functions") {
          for (var fitr = itr->children; fitr != null; fitr = fitr->next) {
            var symbol_item = new SymbolItem ();
            symbol_item.symbol_type = fitr->get_prop ("type");
            symbol_item.name = fitr->get_prop ("name");
            symbol_item.link = get_relative_uri (item.link, fitr->get_prop ("link"));
            symbols.append (symbol_item);
          }
        }
      }
      item.sub_items = sub_items;
      item.symbols = symbols;
      delete tree;
      return item;
    }
  }

  public class DocFactory : Object {

    private File? doc_dir { private set; get; }

    private ListStore docs;

    public DocFactory (string doc_dir_path = get_doc_dir ()) {
      this.doc_dir = File.new_for_path (doc_dir_path);
      this.docs = load_from_file_async ();
    }

    protected ListStore load_from_file_async (Cancellable? cancellable = null) {
      try {
        var docs = new ListStore (typeof (LinkItem));
        var enumerator = doc_dir.enumerate_children ("standard::*", FileQueryInfoFlags.NONE, cancellable);

        FileInfo? file_info;
        while ((file_info = enumerator.next_file (cancellable)) != null) {
          var cur_file = doc_dir.resolve_relative_path (file_info.get_name ());
          var help_file = cur_file.resolve_relative_path (file_info.get_name () + ".devhelp2");
          if (help_file.query_exists (cancellable)) {
            docs.append (DocFileItem.read_from_devhelp_file (help_file));
          }
        }

        docs.sort ((a_obj, b_obj) => {
          var a = a_obj as LinkItem, b = b_obj as LinkItem;
          return a.name > b.name ? 1 : a.name == b.name ? 0 : -1;
        });

        return docs;
      } catch (Error e) {
        return new ListStore (typeof (LinkItem));
      }
    }

    public Gtk.TreeListModel create_doc_tree_model () {
      return new Gtk.TreeListModel (docs, false, false, (item) => {
        var it = item as LinkItem;
        if (it == null || it.sub_items == null || it.sub_items.get_n_items () == 0) {
          return null;
        }
        return it.sub_items;
      });
    }

    public ListModel create_symbol_list_model (string keyword) {
      var symbols = new ListStore (typeof (LinkItem));
      var max_symbols = 100;
      for (var i = 0; i < docs.get_n_items () && symbols.get_n_items () < max_symbols; i++) {
        var it = docs.get_item (i) as DocFileItem;
        if (it == null) {
          continue;
        }
        for (var j = 0; j < it.symbols.get_n_items () && symbols.get_n_items () < max_symbols; j++) {
          var sym = it.symbols.get_item (j) as SymbolItem;
          if (sym != null && sym.name.contains (keyword)) {
            symbols.append (sym);
          }
        }
      }
      return symbols;
    }
  }
}