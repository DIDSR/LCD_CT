from pathlib import Path

from oct2py import octave

import numpy as np
from sklearn.model_selection import train_test_split
import pandas as pd


class Observer:
    def __init__(self, signal_present, signal_absent):
        # subtract DC component
        self.signal_present = signal_present - signal_present.mean()
        self.signal_absent = signal_absent - signal_absent.mean()

    def __repr__(self):
        return f'''{self.__class__.__name__}
signal present array shape [z, x, y]: {self.signal_present.shape}
signal absent array shape [z, x, y]:  {self.signal_absent.shape}'''

    def calculate_auc(self, signal_absent_train, signal_present_train,
                      signal_absent_test, signal_present_test):
        pass

    def get_splits(self, pct_split=0.5, seed=None):
        'returns: sa_train, sp_train, sa_test, sp_test'
        sp_train, sp_test, sa_train, sa_test = train_test_split(self.signal_present,
                                                                self.signal_absent,
                                                                train_size=pct_split,
                                                                shuffle=True,
                                                                random_state=seed)
        return sa_train, sp_train, sa_test, sp_test

    def run_study(self, n_readers=10, pct_split=0.5, seed=None):
        random = np.random.default_rng(seed=seed)
        seed_split = random.integers(0, 1e5, size=n_readers)
        aucs = []
        snrs = []
        readers = []
        observers = []
        for reader in range(n_readers):
            sp_train, sp_test, sa_train, sa_test = self.get_splits(pct_split=pct_split,
                                                                   seed=seed_split[reader])
            output_dict = self.calculate_auc(sa_train, sp_train, sa_test, sp_test)
            observers.append(self.__class__.__name__)
            aucs.append(output_dict['auc'])
            snrs.append(output_dict['snr'])
            readers.append(reader)
        return pd.DataFrame({'observer': observers, 'auc': aucs, 'snr': snrs,
                             'reader': readers})


class LG_CHO(Observer):
    def __init__(self, signal_present, signal_absent, channel_width, n_channels=5):
        super().__init__(signal_present, signal_absent)
        self.channel_width = channel_width
        self.n_channels = n_channels

    def calculate_auc(self, signal_absent_train, signal_present_train,
                      signal_absent_test, signal_present_test):
        curdir = Path(__file__).parent.absolute()
        octave.addpath(str(curdir / 'functions'))

        signal_absent_train = signal_absent_train.transpose(1, 2, 0)
        signal_present_train = signal_present_train.transpose(1, 2, 0)
        signal_absent_test = signal_absent_test.transpose(1, 2, 0)
        signal_present_test = signal_present_test.transpose(1, 2, 0)

        [auc, snr, chimg, tplimg, meanSP, meanSA, meanSig, k_ch, t_sp, t_sa] =\
            octave.lg_cho_2d(signal_absent_train, signal_present_train,
                             signal_absent_test, signal_present_test,
                             self.channel_width, self.n_channels, nout=10)
        return {'auc': auc, 'snr': snr, 'channel image': chimg, 'template': tplimg,
                'mean signal present': meanSP, 'mean signal absent': meanSA,
                'mean signal': meanSig, 'channel matrix': k_ch, 't score SP': t_sp, 't score SA': t_sa}


class DOG_CHO(Observer):
    def __init__(self, signal_present, signal_absent, type='dense'):
        super().__init__(signal_present, signal_absent)
        self.type = type

    def calculate_auc(self, signal_absent_train, signal_present_train,
                      signal_absent_test, signal_present_test):
        curdir = Path(__file__).parent.absolute()
        octave.addpath(str(curdir / 'functions'))

        signal_absent_train = signal_absent_train.transpose(1, 2, 0)
        signal_present_train = signal_present_train.transpose(1, 2, 0)
        signal_absent_test = signal_absent_test.transpose(1, 2, 0)
        signal_present_test = signal_present_test.transpose(1, 2, 0)

        [auc, snr, t_sa, t_sp, meanSA, meanSP, meanSig, tplimg, chimg, k_ch] =\
            octave.dog_cho_2d(signal_absent_train, signal_present_train,
                              signal_absent_test, signal_present_test,
                              self.type, nout=10)
        return {'auc': auc, 'snr': snr, 'channel image': chimg,
                'template': tplimg, 'mean signal present': meanSP,
                'mean signal absent': meanSA, 'mean signal': meanSig,
                'channel matrix': k_ch, 't score SP': t_sp, 't score SA': t_sa}


class Gabor_CHO(Observer):
    def __init__(self, signal_present, signal_absent, nband=4, ntheta=4, phase=0):
        super().__init__(signal_present, signal_absent)
        self.nband = nband
        self.ntheta = ntheta
        self.phase = phase

    def calculate_auc(self, signal_absent_train, signal_present_train,
                      signal_absent_test, signal_present_test):
        curdir = Path(__file__).parent.absolute()
        octave.addpath(str(curdir / 'functions'))

        signal_absent_train = signal_absent_train.transpose(1, 2, 0)
        signal_present_train = signal_present_train.transpose(1, 2, 0)
        signal_absent_test = signal_absent_test.transpose(1, 2, 0)
        signal_present_test = signal_present_test.transpose(1, 2, 0)

        [auc, snr, t_sa, t_sp, meanSA, meanSP, meanSig, tplimg, chimg, k_ch] =\
            octave.gabor_cho_2d(signal_absent_train, signal_present_train,
                                signal_absent_test, signal_present_test,
                                self.nband, self.ntheta, self.phase, nout=10)
        return {'auc': auc, 'snr': snr, 'channel image': chimg,
                'template': tplimg, 'mean signal present': meanSP,
                'mean signal absent': meanSA, 'mean signal': meanSig,
                'channel matrix': k_ch, 't score SP': t_sp, 't score SA': t_sa}


class NPWE(Observer):
    def __init__(self, signal_present, signal_absent, eye=False):
        'eye = human eye filter to reduce performance'
        super().__init__(signal_present, signal_absent)
        self.eye = eye

    def calculate_auc(self, signal_absent_train, signal_present_train,
                      signal_absent_test, signal_present_test):
        curdir = Path(__file__).parent.absolute()
        octave.addpath(str(curdir / 'functions'))

        signal_absent_train = signal_absent_train.transpose(1, 2, 0)
        signal_present_train = signal_present_train.transpose(1, 2, 0)
        signal_absent_test = signal_absent_test.transpose(1, 2, 0)
        signal_present_test = signal_present_test.transpose(1, 2, 0)

        [auc, snr, t_sp, t_sa, meanSA, meanSP, meanSig, tplimg, eyefunc] =\
            octave.npwe_2d(signal_absent_train, signal_present_train,
                           signal_absent_test, signal_present_test,
                           self.eye, nout=9)
        return {'auc': auc, 'snr': snr,
                'template': tplimg, 'mean signal present': meanSP,
                'mean signal absent': meanSA, 'mean signal': meanSig,
                't score SP': t_sp, 't score SA': t_sa, 'eye function': eyefunc}
