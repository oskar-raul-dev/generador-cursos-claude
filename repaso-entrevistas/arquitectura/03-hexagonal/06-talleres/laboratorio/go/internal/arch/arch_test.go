// Package arch verifica la regla de dependencias leyendo los import de cada archivo con
// go/parser: el ArchUnit de este sabor, sin dependencias.
package arch

import (
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

type rule struct {
	dir       string
	forbidden []string
}

var rules = []rule{
	{dir: "../domain", forbidden: []string{"hexorders/internal/application", "hexorders/internal/infrastructure", "github.com/", "go.mongodb.org/", "golang.org/x/"}},
	{dir: "../application", forbidden: []string{"hexorders/internal/infrastructure", "github.com/", "go.mongodb.org/", "golang.org/x/", "net/http", "database/sql"}},
	{dir: "../infrastructure/inbound", forbidden: []string{"hexorders/internal/infrastructure/outbound"}},
}

func TestDependencyRule(t *testing.T) {
	fset := token.NewFileSet()
	for _, r := range rules {
		err := filepath.WalkDir(r.dir, func(path string, d os.DirEntry, err error) error {
			if err != nil || d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
				return err
			}
			file, err := parser.ParseFile(fset, path, nil, parser.ImportsOnly)
			if err != nil {
				return err
			}
			for _, imp := range file.Imports {
				spec := strings.Trim(imp.Path.Value, `"`)
				for _, f := range r.forbidden {
					if strings.HasPrefix(spec, f) {
						t.Errorf("%s imports %s (forbidden in %s)", path, spec, r.dir)
					}
				}
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
}
