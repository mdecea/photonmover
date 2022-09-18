import os
import ast


class ClassParser:

    """
    This class parses all the .py files in a specified folder, and returns
    a list containing all the class names defined in those files.
    """

    def __init__(self):
        pass

    def class_list(self, folder, recursive=False):
        """
        Parses all the .py files in a specified folder, and returns a list
        containing all the class names defined in those files.
        :param folder: the folder of interest
        :param recursive: if True, it does a recursive search within the
            folders in the base folder
        """

        cl_list = []
        mod_list = []

        if recursive:
            for root, _, files in os.walk(folder):
                for f in files:
                    if f.endswith(".py"):
                        cl_l = self.get_classes(os.path.join(root, f))
                        cl_list.extend(cl_l)
                        mod_str = os.path.join(root, f)
                        mod = mod_str.replace('../', '')
                        mod = mod.replace('./', '')
                        mod = mod.replace('/', '.')
                        mod = mod.replace('.py', '')
                        mod_list.extend([mod] * len(cl_l))
        else:
            for f in os.listdir(folder):
                if f.endswith(".py"):
                    cl_l = self.get_classes(os.path.join(folder, f))
                    cl_list.extend(cl_l)

                    mod_str = os.path.join(folder, f)
                    mod = mod_str.replace('../', '')
                    mod = mod.replace('./', '')
                    mod = mod.replace('/', '.')
                    mod = mod.replace('.py', '')
                    mod_list.extend([mod] * len(cl_l))

        return mod_list, cl_list

    def get_classes(self, filename):
        # Returns a list with all the classes defined in the specified filename
        class_list = list()
        with open(filename, "r") as file_obj:
            text = file_obj.read()
            p = ast.parse(text)
            node = ast.NodeVisitor()

            for node in ast.walk(p):
                if isinstance(node, ast.ClassDef):
                    class_name = node.name
                    class_list.append(class_name)

        return class_list


if __name__ == '__main__':

    cp = ClassParser()
    a = cp.class_list("../experiments/", True)
    print(a[0])
    print(a[1])
