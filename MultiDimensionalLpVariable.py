import pulp
import numpy

class MultiDimensionalLpVariable:
    def __init__(self, name, dimensions, low_bound, up_bound, cat):
        self.name = name
        try:
            self.dimensions = (*dimensions,)
        except:
            self.dimensions = (dimensions,)
        self.low_bound = low_bound
        self.up_bound = up_bound
        assert cat in pulp.LpCategories, 'cat must be one of ("{}").'.format(
            '", "'.join(pulp.LpCategories)
        )
        self.cat = cat
        self.variables = self._build_variables_array()
        self.values = None

    def __getitem__(self, index): # __getitem__() is a magic method in Python, which when used in a class, allows its instances to use the [] (indexer) operators
        return self.variables[index]

    def _build_variables_array(self):
        f = numpy.vectorize(self._define_variable) # numpy.vectorize Generalized function class.
        return numpy.fromfunction(f, self.dimensions, dtype="int") # numpy.fromfunction construct an array by executing a function over each coordinate.

    def _define_variable(self, *index):
        name = "_".join(map(str, (self.name, *index)))
        return pulp.LpVariable(name, self.low_bound, self.up_bound, self.cat)

    def evaluate(self):
        f = numpy.vectorize(lambda i: pulp.value(i))
        self.values = f(self.variables)